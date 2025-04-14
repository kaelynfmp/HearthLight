extends Node

signal inventory_open_state_changed
signal computer_visibility_changed
signal update_recipes
signal pause_changed
signal update_gadgets
signal update_items
signal take_cursor(Slot)
signal debug_mode_change
signal gadget_rotated(direction: int)
signal awaken
signal paid_off_debt
signal teleporter_list_changed
signal right_click_pressed
signal gadget_changed
signal teleporter_removed(teleporter: InWorldGadget)

@onready var computer_gadget:Gadget = load("res://resources/gadgets/computer.tres")

var character:Character

var inventory: bool = false:
	set(value):
		inventory = value
		if !value:
			gadget = null
var gadget:InWorldGadget

var computer_visible:bool = false
var computer_tab_manager:TabContainer
var has_cyber_generator = false
var cyber_generator = null
var blur:bool = false

# Temp
var is_placing_gadget: bool = false

var is_debugging: bool = false

var cursor:Node2D

var inventories: Array[Inventory] = []
var player_inventory: Inventory

var slot_distributor: Dictionary = {"total": 0, "item": null, "slots": [], "distributed": []} 

enum Items {
	MAX = 999999999999999999,
	MAX_STACK = 999,
	DEFAULT_STACK = 100
}

enum Load_Type {
	RECIPE, GADGET, ITEM
}

enum Age {
	PRIMITIVE, INDUSTRIAL, ELECTRICAL, CYBER
}

enum CUTSCENE_TYPE {
	AWAKEN, FREE_PLAY, MAIN_MENU
}

var recipe_strings:Array[String]
var gadget_strings:Array[String]
var item_strings:Array[String]

var currency: int = 20
signal currency_updated(new_amount)


var debt:int = 10000
var debt_days:int = 21
var debt_paid:bool = false

var cutscene_displayed:bool = true
@onready var current_cutscene:Cutscene = load("res://resources/cutscenes/intro.tres")

var starting_hour: int = 8
var last_hour: int = 24
var hours: int = last_hour - starting_hour
var max_time_seconds: int = hours * 3600
var max_time: int = max_time_seconds * 1000
var start_time: int
var current_time: int
var active_time: int = 0 # time spent with the time moving, aka out of pause/computer, PER DAY, resets every day
var seconds_elapsed: float
var milliseconds_elapsed: int
var day_hours: int  = 18
var time_scale: int = 480 # 1 irl second is 480 game seconds for 2 minutes/day, 16h day
var time_scaled_seconds: int
var time_difference
var continue_clock_in_computer: int = 5000
var time_final: bool
var sleeping: bool
var sleeping_time
var sleep_start
var sleep_end
var game_time: Dictionary = {
	"day": 1,
	"hour": 8,
	"minute": 0,
	"second": 0,
	"segment": "morning"
}
var in_computer: bool
var shop_dict: Dictionary = {
	"resources": [],
	"gadgets": [],
	"wanted": []
}
var shop_categories: Dictionary[String, Control]
var buyable_items: Dictionary[Item, Button]
var unlocked_items: Array[Item]
var gadgets_unlocked: bool = false
var resources_unlocked: bool = false

var categorized_emails: Dictionary = {
	"orders": [],
	"main": [],
	"spam": [],
	"archive": []
}
var all_order_emails: Array[Email]
var all_lore_emails : Array[Email]
var all_tutorial_emails : Array[Email]
var all_bankruptcy_emails: Array[Email]

var random_email_amount:int = 2

var pause: bool = true

var recipes:Array[Recipe]
var gadgets:Array[Gadget]
var gadget_items:Dictionary[Item, Gadget]
var items:Array[Item]

var day_start_sound:AudioStreamPlayer2D
var day_end_sound:AudioStreamPlayer2D

var teleporters:Array[InWorldGadget]

var room_map = []
var item_map = []

var quest_list_visible:bool = true

func init_room_map():
	var map = []
	for i in range(15):
		var row = []
		for j in range(15):
			row.append(null)
		map.append(row)
	return map

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	start_time = Time.get_ticks_msec()
	seconds_elapsed = 0
	room_map = init_room_map()
	item_map = init_room_map()
	load_recipes()
	load_gadgets()
	load_items()
	
	#for recipe in recipes:
		#print("inputs: ", recipe.inputs, " gadget: ", recipe.gadget)
	
func _process(_delta: float) -> void:
	if cutscene_displayed:
		return
	if Input.is_action_just_pressed("inventory"):
		if !pause:
			if !GameManager.computer_visible:
				change_inventory()
			else:
				change_computer_visibility()
	elif Input.is_action_just_pressed("toggle_pause"):
		if !GameManager.computer_visible and !inventory:
			pause = !pause
			pause_changed.emit()
		elif GameManager.computer_visible:
			change_computer_visibility()
		else:
			change_inventory()
			
	elif Input.is_action_just_pressed("toggle_debug_mode"):
		is_debugging = !is_debugging
		debug_mode_change.emit()
	
	elif Input.is_action_just_pressed("day_progress"):
		if GameManager.computer_visible:
			change_computer_visibility()
		update_time(max_time_seconds)
		
	elif Input.is_action_just_pressed("rotate_gadget"):
		if GameManager.cursor != null:
			var cursor_gadget = get_gadget_from_cursor()
			if cursor_gadget != null and cursor_gadget.name in ["Conveyor Belt", "Teleporter"]:
				cursor_gadget.direction = (cursor_gadget.direction + 1) % 4
				gadget_rotated.emit(cursor_gadget.direction)
			elif GameManager.gadget != null and GameManager.gadget.gadget_stats.name in ["Conveyor Belt", "Teleporter"]:
				GameManager.gadget.direction = (GameManager.gadget.direction + 1) % 4
				gadget_rotated.emit(GameManager.gadget.direction)
	
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		right_click_pressed.emit()
		
		
	blur = inventory
	is_placing_gadget = false
	if cursor != null:
		if cursor.slot != null:
			if cursor.slot.item != null:
				var is_there:bool
				for item in gadget_items:
					if item.name == cursor.slot.item.name:
						is_there = true
				if is_there:
					blur = false
					is_placing_gadget = true
					
func _physics_process(_delta: float) -> void:
	# time tracking
	if cutscene_displayed:
		return
	milliseconds_elapsed = active_time
	seconds_elapsed = milliseconds_elapsed / 1000
	time_scaled_seconds = seconds_elapsed*time_scale
	var less_rounded_seconds:int = int(milliseconds_elapsed / 1000.0 * time_scale)
	time_final = less_rounded_seconds >= max_time_seconds - continue_clock_in_computer # If it is time to start ticking and playing the audio
	if !pause and (!in_computer or (!pause and in_computer and time_final) or sleeping):
		current_time = Time.get_ticks_msec()
		time_difference = current_time - start_time
		start_time = Time.get_ticks_msec()
		if !sleeping:
			active_time += time_difference
	
		if !sleeping:
			update_time(time_scaled_seconds)
			if (time_final):
				if not day_end_sound.playing:
					
					day_end_sound.play()
		elif sleeping: # TODO: whatever animations, etc
			#await get_tree().create_timer(3).timeout
			wake_up()
			start_time = Time.get_ticks_msec()
	else:
		start_time = Time.get_ticks_msec()

## Load all recipes in the filesystem
func load_recipes():
	update_recipes.emit()
	recipe_strings = Utility.load_path("res://resources/recipes")
	for recipe_string:String in recipe_strings:
		recipes.append(load(recipe_string))

## Load all gadgets in the filesystem
func load_gadgets():
	update_gadgets.emit()
	gadget_strings = Utility.load_path("res://resources/gadgets")
	for gadget_string:String in gadget_strings:
		var curr_gadget:Gadget = load(gadget_string)
		gadgets.append(curr_gadget)
		gadget_items[curr_gadget.item] = curr_gadget
		
## Load all items in the filesystem
func load_items():
	update_items.emit()
	item_strings = Utility.load_path("res://resources/items")
	for item_string:String in item_strings:
		var item:Item = load(item_string)
		items.append(item)

## Changes whether the inventory is open or not
func change_inventory():
	if inventory:
		if gadget != null:
			if gadget.gadget_stats.close_sound != null:
				gadget.play_close_sound()
		inventory = false
		inventories.clear()
		if cursor != null:
			if cursor.slot != null:
				if cursor.slot.item != null:
					take_cursor.emit(cursor.slot.duplicate())
					cursor.slot.decrement(cursor.slot.quantity)
	else:
		inventory = true
	inventory_open_state_changed.emit()

## Adds an inventory to the master list
func add_inventory(p_inventory: Inventory):
	inventories.append(p_inventory)

## Attempts to send a slot to the nearest inventory, and will spread them out among multiple if necessary to send it all
func send_to_inventory(slot: Slot):
	var home_inventory: Inventory
	var temp_slot:Slot = slot.duplicate()
	var starting_quantity = slot.duplicate().quantity
	var starting_item = slot.duplicate().item
	slot.decrement(starting_quantity)
	for search_inventory in inventories:
		if slot not in search_inventory.slots:
			var remainder = search_inventory.insert(temp_slot.item, temp_slot.quantity)
			temp_slot.decrement(temp_slot.quantity - remainder)
			if temp_slot.quantity == 0:
				break
		else:
			home_inventory = search_inventory

	if home_inventory == null:
		home_inventory = player_inventory
	
	if temp_slot.quantity > 0:
		var remainder = home_inventory.insert(temp_slot.item, temp_slot.quantity)
		temp_slot.decrement(temp_slot.quantity - remainder)

	slot.initialize(starting_item, slot.quantity + temp_slot.quantity, true)

## Sets the cursor object
func set_cursor(setting_cursor: Node2D):
	cursor = setting_cursor
	
## Appends to the slot distributor, which is a list of currently dragged over slots, and will balance out how many items
## are in them all, with a total quantity and an item
func initialize_slot_distributor(total: int, item: Item):
	slot_distributor.total = total
	slot_distributor.item = item

### Appends to the slot distributor, which is a list of currently dragged over slots, and will balance out how many items
### are in them all
func append_slot_distributor(slot: Slot, add: int = 0) -> bool:
	if slot not in slot_distributor.slots and slot.can_insert(slot_distributor.item):
		slot_distributor.total += add
		slot_distributor.slots.append(slot)
		distribute_slots()
		return true
	return false
	
## Distributes the slots evenly among every slot in the slot distributor
func distribute_slots() -> void:
	var remainder = slot_distributor.total
	slot_distributor.distributed.resize(slot_distributor.slots.size())
	slot_distributor.distributed.fill(0)
	while remainder > 0:
		for index: int in range(slot_distributor.slots.size()):
			slot_distributor.distributed[index] += 1
			remainder -= 1
			if remainder == 0:
				for subindex: int in range(slot_distributor.slots.size()):
					slot_distributor.slots[subindex].initialize(slot_distributor.item, slot_distributor.distributed[subindex])
				return
	
## Sets the currently selected gadget
func set_gadget(p_gadget:InWorldGadget) -> void:
	if inventory:
		if gadget != null:
			inventories.erase(gadget.inventory)
			if gadget.gadget_stats.close_sound != null and gadget.gadget_stats.name != p_gadget.gadget_stats.name:
				gadget.play_close_sound()
	gadget = p_gadget
	gadget_changed.emit()
	if !inventory:
		change_inventory()
	inventories.append(p_gadget.inventory)
	if p_gadget.gadget_stats.open_sound != null:
		p_gadget.play_open_sound()
		
## Gets the current gadget that corresponds to the item held in the cursor
func get_gadget_from_cursor() -> Gadget:
	if !cursor.slot or !cursor.slot.item:
		return null
	for item in gadget_items:
		if item.name == cursor.slot.item.name:
			return gadget_items[item]
	return null
	
## Adds a teleporter to the teleporter list and emits a signal that it has been changed
func add_teleporter(_gadget: InWorldGadget):
	teleporters.append(_gadget)
	teleporter_list_changed.emit()
	
## Removes a teleporter to the teleporter list and emits a signal that it has been changed
func remove_teleporter(_gadget: InWorldGadget):
	teleporters.erase(_gadget)
	teleporter_list_changed.emit()
	teleporter_removed.emit(_gadget)

## Clears the slot distributor, which is a list of currently dragged over slots, and will balance out how many items
## are in them all
func clear_slot_distributor():
	slot_distributor.total = 0
	slot_distributor.item = null
	slot_distributor.slots = []

func add_currency(amount: int):
	currency += amount
	currency_updated.emit(currency)
	
func subtract_currency(amount: int) -> bool:
	if currency >= amount:
		currency -= amount
		currency_updated.emit(currency)
		return true  # successful purchare
	return false  # not enough money for purchase

## Picks up a gadget and puts it into the cursor
func pickup_gadget(_gadget:Gadget, direction:Gadget.Direction = Gadget.Direction.SE) -> bool:
	if cursor != null and cursor.slot != null and cursor.slot.item == null:
		if !inventory:
			change_inventory()
		cursor.slot.initialize(_gadget.item)
		get_gadget_from_cursor().direction = direction
		AudioManager.play_button_sound(AudioManager.BUTTON.PICK_UP, 0.0, 1.0, 0.0)
		return true
	return false
	
func has_unreads() -> bool:
	for category in categorized_emails.values():
		if category.any(func(email: Email): return email.check_valid() and not email.is_read):
			return true
	return false
	
func unique_gadget_interaction(_gadget:Gadget):
	if _gadget == computer_gadget:
		change_computer_visibility()
		
func change_computer_visibility():
	if inventory:
		change_inventory()
	computer_visible = !computer_visible
	computer_visibility_changed.emit()
	in_computer != in_computer
	
func player_inventory_has(required_items:Array[Resource], required_quantities:Array[int]) -> bool:
	if required_items.size() != required_quantities.size():
		printerr("Fed incongruent required_items and required_quantities to player_inventory_has")
	var loop_size = min(required_items.size(), required_quantities.size()) # If the arrays are misaligned, align to the smaller of the two
	for index in range(loop_size):
		var to_parse_item: Item
		if required_items[index] is Gadget:
			to_parse_item = required_items[index].item
		else:
			to_parse_item = required_items[index]
		if player_inventory.get_item_quantity(to_parse_item) < required_quantities[index]:
			return false
	return true
	
func unlock_item(unlock:Resource):
	if unlock is Gadget:
		unlocked_items.append(unlock.item)
		buyable_items[unlock.item].unlock()
		shop_categories["gadgets"].unlock()
		gadgets_unlocked = true
	elif unlock is Item:
		unlocked_items.append(unlock)
		buyable_items[unlock as Item].unlock()
		shop_categories["resources"].unlock()
		resources_unlocked = true

func navigate_to_botsy():
	if computer_tab_manager != null:
		computer_tab_manager.current_tab = 1

func update_time(in_game_seconds):
	#print("Game Seconds: %s" % in_game_seconds)	
	game_time["hour"] = int(in_game_seconds / 3600) + starting_hour
	game_time["minute"] = int((in_game_seconds % 3600) / 60)
	game_time["second"] = int(in_game_seconds % 60)
	
	# count days
	if (game_time["hour"] == last_hour):
		go_sleep()
	

	# update day segment aka morning, afternoon etc
	if (8 <= game_time["hour"] and game_time["hour"] < 12):
		game_time["segment"] = "morning"
	elif (12 <= game_time["hour"] and game_time["hour"] < 16):
		game_time["segment"] = "afternoon"
	elif (16 <= game_time["hour"] and game_time["hour"] < 20):
		game_time["segment"] = "evening"
	else: # game time > 20
		game_time["segment"] = "night"
	
	# testing
	#if (game_time["minute"]): # prints on the hour
		#print("IRL Seconds elapsed: ", seconds_elapsed)
		#print("Game Seconds: %s" % in_game_seconds)	
		#print("Game Time: %d Days, %dH %dM %dS" % [game_time["day"], game_time["hour"], game_time["minute"], game_time["second"]])
func is_after_date(day: int, hour: int, minute: int) -> bool:
	var current_day = game_time["day"]
	var current_hour = game_time["hour"]
	var current_minute = game_time["minute"]
	if day < current_day:
		return true
	elif day > current_day:
		return false
	else: # requested day IS the current day
		# check hour and minute
		if hour < current_hour:
			return true
		elif hour > current_hour:
			return false
		else: # it IS the current hour
			if minute <= current_minute:
				return true
			else:
				return false
	return false

func go_sleep():
	sleeping = true
	AudioManager.ambient_audio.stop()
	sleep_start = Time.get_ticks_msec()
	milliseconds_elapsed = active_time
	if computer_visible:
		change_computer_visibility()
	print("starting sleep...")
	#TODO: Sleep behavior
func wake_up():
	sleep_end = Time.get_ticks_msec()
	sleeping_time = sleep_end - sleep_start
	awaken.emit()
	active_time=0
	seconds_elapsed = 0
	#print(sleeping_time)
	if sleeping_time >= 2300:
		if not day_start_sound.playing:
			day_start_sound.play()
	if sleeping_time >= 5000:
		game_time["day"] += 1
		game_time["hour"] = starting_hour
		game_time["minute"] = 0
		game_time["second"] = 0
		sleeping = false
		AudioManager.reset_audio()
		print("waking up...")

func pay_debt():
	if computer_visible:
		computer_visible = false
		computer_visibility_changed.emit()
	paid_off_debt.emit()
	debt_paid = true
	if game_time["day"] > debt_days:
		current_cutscene = load("res://resources/cutscenes/badending.tres")
		AudioManager.transition_bad_ending()
	else:
		current_cutscene = load("res://resources/cutscenes/goodending.tres")
		AudioManager.is_good = true
		AudioManager.transition_good_ending()
	
	cutscene_displayed = true

func conclude_cutscene():
	cutscene_displayed = false
	start_time = Time.get_ticks_msec()
	if not AudioManager.ambient_audio.playing:
		AudioManager.stop_intro()
	if AudioManager.ending_audio.playing:
		AudioManager.transition_after_ending()
	if current_cutscene.cutscene_type == CUTSCENE_TYPE.MAIN_MENU:
		get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
		
		
func check_core_tutorials_done():
	for item in unlocked_items:
		if item.name == "Wood Fire Stove":
			return true
	if is_debugging:
		return true
	return false
