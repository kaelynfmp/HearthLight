extends Node

signal inventory_changed

@export var inventory:bool = false

var cursor:Node2D

var inventories: Array[Inventory] = []

var slot_distributor: Dictionary = {"total": 0, "item": null, "slots": [], "distributed": []} 

enum Items {
	MAX = 999999999999999999,
	MAX_STACK = 999,
	DEFAULT_STACK = 100
}

var currency: int = 20
signal currency_updated(new_amount)

var start_time: int
var current_time: int
var seconds_elapsed: float
var day_hours = 18
var time_scale = 480 # 1 irl second is 480 game seconds for 2 minutes/day, 16h day
var time_scaled_seconds: int
var game_time = {
	"day": 1,
	"hour": 8,
	"minute": 0,
	"second": 0,
	"segment": "morning"
}
var in_computer: bool
var shop_dict = {
	"resources": [],
	"gadgets": []
}

func _ready() -> void:
	start_time = Time.get_ticks_msec()
	seconds_elapsed = 0
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		change_inventory()
	
	# time tracking
	var current_time = Time.get_ticks_msec()
	var milliseconds_elapsed = current_time - start_time
	seconds_elapsed = milliseconds_elapsed / 1000
	time_scaled_seconds = seconds_elapsed*time_scale
	update_time(time_scaled_seconds)
	

func change_inventory():
	if inventory:
		inventory = false
		inventories.clear()
	else:
		inventory = true
	inventory_changed.emit()

func add_inventory(p_inventory: Inventory):
	inventories.append(p_inventory)

func send_to_inventory(slot: Slot):
	var went_somewhere: bool = false
	var home_inventory: Inventory
	var temp_slot: Slot = slot.duplicate()
	for search_inventory in inventories:
		if slot not in search_inventory.slots:
			slot.decrement(slot.quantity)
			went_somewhere = search_inventory.insert(temp_slot.item, temp_slot.quantity)
			return
		else:
			home_inventory = search_inventory

	if !went_somewhere:
		slot.decrement(slot.quantity)
		home_inventory.insert(temp_slot.item, temp_slot.quantity)

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

func update_time(in_game_seconds):
	#print("Game Seconds: %s" % in_game_seconds)	
	game_time["hour"] = int(in_game_seconds / 3600) + 8
	game_time["minute"] = int((in_game_seconds % 3600) / 60)
	game_time["second"] = int(in_game_seconds % 60)
	
	# count days
	if (game_time["hour"] == day_hours + 6): 
		game_time["day"] += 1
		game_time["hour"] = 8
		game_time["minute"] = 0
		game_time["second"] = 0
		start_time = Time.get_ticks_msec()
	
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
