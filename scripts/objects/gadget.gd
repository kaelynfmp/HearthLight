extends StaticBody2D

signal removing(layer_occupied_name:String, cell_pos:Vector2i)
signal item_at_location(cell_pos: Vector2i, item: Item)

@export var gadget_stats:Gadget
@onready var audio_player:AudioStreamPlayer2D = find_child("AudioStreamPlayer")
@onready var open_audio_player:AudioStreamPlayer2D = find_child("OpenAudioPlayer")
@onready var close_audio_player:AudioStreamPlayer2D = find_child("CloseAudioPlayer")
@onready var sprite:AnimatedSprite2D = find_child("Sprite")
@onready var valid_selection:CompressedTexture2D = load("res://scripts/shaders/close_enough_texture.tres")
@onready var invalid_selection:CompressedTexture2D = load("res://scripts/shaders/not_close_enough_texture.tres")
@export var inventory: Inventory
@export var is_holding: bool = false
@export var has_power_from_generator = false
@export var total_power:float = 0.0
@export var power_per_coal = 10

var max_power:int = 1000
# With 6 gadgets, this means 1 coal can power 6 recipes. I.e. 6 simultaneous gadgets can be powered by 
# one generator.
var power_depletion_rate:float = 0.2

var prev_power:float = 0.0

var location: Vector2i
var character: Node2D
var base_layer: Node2D
var tile_layers: Node2D
var age:int
var is_generator:bool = false
var initial_click:bool = true
var progressing:bool = false
var progress:float = 0
var selected_recipe:Recipe
var recipe_taken = false
var layer_occupied_name:String
var cell_pos:Vector2i
var primitive_selected:bool = false
var hovered:bool = false
var recipes:Array[Recipe]
var rear_gadget: StaticBody2D
var front_gadget: StaticBody2D
var corresponding_item: RigidBody2D
enum Direction {SE, SW, NW, NE}
var direction: int
var direction_vector: Array[Vector2i] = [
	Vector2i(-1, 0),
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
]
var disabled = false
var has_power = false
var is_able_to_do_recipe: bool = false
var is_cyber_generator: bool = false
var notification:Sprite2D

func get_local_position():
	return base_layer.map_to_local(cell_pos)

func create_new_inventory(num_inputs: int, num_outputs: int) -> void:
	inventory = Inventory.new()
	inventory.slots = []
	for i in range(num_inputs):
		var slot: Slot = Slot.new()
		slot.item = null
		slot.locked = false
		slot.item_filter = gadget_stats.inventory.slots[i].item_filter
		inventory.slots.append(slot)
	for i in range(num_outputs):
		var slot: Slot = Slot.new()
		slot.item = null
		slot.locked = true
		slot.item_filter = gadget_stats.inventory.slots[num_inputs + i].item_filter
		inventory.slots.append(slot)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_new_inventory(gadget_stats.inputs, gadget_stats.outputs)
	character = get_parent().get_parent().get_parent().find_child("Character")
	base_layer = get_parent()
	tile_layers = base_layer.get_parent()
	age = gadget_stats.age
	is_generator = "Generator" in gadget_stats.name
	is_cyber_generator = gadget_stats.name == "Universal Generator"
	sprite.sprite_frames = gadget_stats.sprite_frames
	sprite.offset = gadget_stats.sprite_offset
	direction = gadget_stats.direction
	sprite.scale *= gadget_stats.sprite_scale_factor
	rotate_sprite()
	if gadget_stats.name == "Conveyor Belt":
		collision_layer = 2
		collision_mask = 2
	audio_player.set_stream(gadget_stats.ambient_sound)
	open_audio_player.set_stream(gadget_stats.open_sound)
	close_audio_player.set_stream(gadget_stats.close_sound)
	update_recipes()
	GameManager.update_recipes.connect(update_recipes)
	notification = find_child("Notification")
	
func check_for_nearby_generator(delta: float):
	for offset_x in range(-2, 3):
		for offset_y in range(-2, 3):
			var target_pos = cell_pos + Vector2i(offset_x, offset_y)
			if GameManager.room_map[target_pos[0] + 6][target_pos[1] + 5] != null:
				var gadget_at_target_pos = GameManager.room_map[target_pos[0] + 6][target_pos[1] + 5]
				if gadget_at_target_pos.is_cyber_generator:
					return true
				if gadget_at_target_pos.is_generator and gadget_at_target_pos.has_power:
					# Deplete power of generator being used
					if progressing and selected_recipe != null and not GameManager.sleeping:
						gadget_at_target_pos.total_power = max(0, gadget_at_target_pos.total_power - power_depletion_rate * delta)
					return true
	return false
	

func _physics_process(delta: float) -> void:
	if not gadget_stats.produces:
		return
	if GameManager.gadget == null:
		primitive_selected = false
	check_for_valid_recipe()
	if gadget_stats.age > GameManager.Age.PRIMITIVE and not is_generator:
		has_power_from_generator = check_for_nearby_generator(delta)
	if is_generator:
		has_power = total_power > 0 or is_cyber_generator
		if prev_power != total_power or is_cyber_generator:
			prev_power = total_power
			if not AudioManager.active_gadgets[gadget_stats.sound_string].has(self):
				AudioManager.active_gadgets[gadget_stats.sound_string][self] = true
		else:
			if AudioManager.active_gadgets[gadget_stats.sound_string].has(self):
				AudioManager.active_gadgets[gadget_stats.sound_string].erase(self)
	if !disabled and !progressing or (!progressing and selected_recipe != null) and not GameManager.sleeping:
		if gadget_stats.name == "Conveyor Belt":
			do_transport()
		elif selected_recipe != null:
			is_able_to_do_recipe = is_able_to_recipe()
			if is_able_to_do_recipe:
				disabled = false
				do_recipe()
			else:
				disabled = true
	else:
		var change_rate:float = (delta / gadget_stats.process_time) * (
			selected_recipe.processing_multiplier if selected_recipe else 1.0)
		if not GameManager.sleeping and ((recipe_taken or selected_recipe != null) and \
		((age > GameManager.Age.PRIMITIVE and not is_generator and has_power_from_generator) or \
		primitive_selected or is_generator)):
			if is_generator:
				if total_power < max_power:
					progress += change_rate
					var power_rate:float = change_rate * power_per_coal
					total_power = min(total_power + power_rate, max_power)
			else:
				progress += change_rate
		else:
			progress -= change_rate
		if progress >= 1:
			if gadget_stats.name != "Conveyor Belt":
				finish_recipe()
			else:
				finish_transport()
		elif progress <= 0:
			cancel_processing()
	if GameManager.inventory and GameManager.gadget == self and !detect_nearby():
		GameManager.change_inventory()

func is_able_to_recipe() -> bool:
	var recipe_inputs: Array[Slot] = selected_recipe.inputs
	var input_slots: Array[Slot] = inventory.slots.filter(func(slot): return !slot.locked)
	var have_enough_inputs: bool = recipe_inputs.all(
		func(recipe_input_slot):
			var item = recipe_input_slot.item
			var required: bool = input_slots.any(
				func(input_slot):		
					return input_slot.item.name == item.name and input_slot.quantity >= recipe_input_slot.quantity
			)
			return required
	)
	var output_slots: Array = inventory.slots.filter(func(slot): return slot.locked)
	var is_able: bool = output_slots.all(func(slot):
		var item = slot.item
		if item == null:
			return true
		var slot_item_in_recipe = selected_recipe.outputs.find_custom(func(output): 
			return output.item.name == item.name)
		if slot.quantity + selected_recipe.outputs[slot_item_in_recipe].quantity <= item.max_stack:
			return true
	)
	return is_able and have_enough_inputs
	
func rotate_sprite() -> void:
	match (direction):
		Direction.SE:
			sprite.animation = "se"
		Direction.SW:
			sprite.animation = "sw"
		Direction.NE:
			sprite.animation = "ne"
		Direction.NW:
			sprite.animation = "nw"
	
func _process(_delta: float) -> void:
	#direction = gadget_stats.direction
	rotate_sprite()
	if hovered:
		sprite.material.set("shader_parameter/textureScale", Vector2.ONE)
		if detect_nearby():
			sprite.material.set("shader_parameter/scrollingTexture", valid_selection)
		else:
			sprite.material.set("shader_parameter/scrollingTexture", invalid_selection)
	else:
		sprite.material.set("shader_parameter/textureScale", Vector2.ZERO)
		pass
		
	if gadget_stats.name == "Computer":
		if GameManager.has_unreads():
			notification.set_visible(true)
		else:
			notification.set_visible(false)
		
func do_transport():
	var rear_gadget_pos: Vector2i = cell_pos + direction_vector[direction]
	if (GameManager.room_map[rear_gadget_pos[0] + 6][rear_gadget_pos[1] + 5] != null):
		rear_gadget = GameManager.room_map[rear_gadget_pos[0] + 6][rear_gadget_pos[1] + 5]
		if rear_gadget != null and rear_gadget.gadget_stats.name != "Conveyor Belt":
			start_progression_transport()
			
func start_progression_transport():
	play_sound()
	pull_inventory()
	progressing = true
	
func finish_transport():
	cancel_processing()
		
func pull_inventory():
	if GameManager.item_map[cell_pos[0] + 6][cell_pos[1] + 5] == null: 
		if rear_gadget:
			var rear_inventory: Inventory = rear_gadget.inventory
			var rear_slots = rear_inventory.slots.filter(func(slot): return slot.locked)
			if rear_gadget.gadget_stats.name == "Storage":
				rear_slots = rear_inventory.slots.filter(func(slot): return !slot.locked)
			for slot in rear_slots:
				if slot.item != null:
					var item: Item = slot.item
					if rear_gadget.gadget_stats.name != "Conveyor Belt":
							item_at_location.emit(cell_pos, item)
					rear_inventory.remove_items(item, 1, slot.locked)
					break
					

func update_recipes():
	recipes.clear()
	for recipe:Recipe in GameManager.recipes:
		if recipe.gadget == gadget_stats:
			recipes.append(recipe)
		
func check_for_valid_recipe() -> void:
	if age > GameManager.Age.PRIMITIVE and not is_generator and not has_power_from_generator:
		selected_recipe = null
		return
	for recipe in recipes:
		var inputs:Array[Slot] = inventory.slots.filter(func(slot): return !slot.locked)
		var valid:int = 0
		for input in recipe.inputs:
			for slot in inventory.slots.filter(func(slot): return !slot.locked):
				if slot.item != null and slot.item.name == input.item.name and slot.quantity >= input.quantity:
					valid += 1
		if valid == inputs.size():
			# valid!
			selected_recipe = recipe
			return
	selected_recipe = null
	return
	
func do_recipe():
	if age > GameManager.Age.PRIMITIVE or primitive_selected:
		start_progression()

func start_progression():
	recipe_taken = false
	if is_generator:
		recipe_take()
	progressing = true
	play_sound()
	if not is_generator:
		if gadget_stats.sound_string != null and gadget_stats.sound_string != "":
			# 'True' is arbitrary value, this is a dictionary only to preserve uniqueness
			AudioManager.active_gadgets[gadget_stats.sound_string][self] = true
	
func recipe_take():
	for input in selected_recipe.inputs:
		# We know that the recipe is valid, so we can just remove willy nilly
		for slot in inventory.slots.filter(func(slot): return !slot.locked):
			if slot.item != null and slot.item.name == input.item.name:
				inventory.remove_items(slot.item, input.quantity)
	recipe_taken = true

func finish_recipe():
	if not is_generator:
		recipe_take()
		for output in selected_recipe.outputs:
			inventory.insert(output.item, output.quantity, true)
	cancel_processing()
	
func cancel_processing():
	progress = 0.0
	progressing = false
	audio_player.stop()
	if not is_generator:
		if gadget_stats.sound_string != null and gadget_stats.sound_string != "":
			if AudioManager.active_gadgets[gadget_stats.sound_string].has(self):
				AudioManager.active_gadgets[gadget_stats.sound_string].erase(self)
	if gadget_stats.name != "Conveyor Belt":
		recipe_taken = false

func add_item_to_inventory() -> void:
	var item: Item = load("res://resources/items/cotton.tres")
	collect(item)
		
## 'Collects' a given item, placing it into the inventory on the nearest open slot
func collect(item: Item):
	character.inventory.insert(item)

# Temporary highlight
func _on_mouse_entered() -> void:
	hovered = true

func _on_mouse_exited() -> void:
	initial_click = false
	hovered = false

func detect_nearby() -> bool:
	var character_cell_position: Vector2 = base_layer.local_to_map(character.global_position)
	var gadget_cell_position: Vector2 = base_layer.local_to_map(global_position)
	return character_cell_position.distance_squared_to(gadget_cell_position) <= 6.0

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if detect_nearby() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if !initial_click:
			if gadget_stats.produces:
				GameManager.set_gadget(self)
			else:
				GameManager.unique_gadget_interaction(gadget_stats)
	elif detect_nearby() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if GameManager.pickup_gadget(gadget_stats, direction):
			cancel_processing()
			# Remove from masterlist of inventories
			GameManager.inventories.erase(inventory)
			for slot in inventory.slots:
			# Send it all away to any open inventories
				GameManager.send_to_inventory(slot)
			if gadget_stats.age > Gadget.Age.PRIMITIVE:
				if AudioManager.active_gadgets[gadget_stats.sound_string].has(self):
					(func(): AudioManager.active_gadgets[gadget_stats.sound_string].erase(self)).call_deferred()
			removing.emit(layer_occupied_name, cell_pos)
			queue_free()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		if initial_click:
			if event.is_released():
				initial_click = false

func play_sound() -> void:
	if progressing:
		audio_player.play()
	# TODO: implement later
	#if age == "Primitive":
	#	if is_holding:
	#		audio_player.stream_paused = false
	#		#print("play")
	#	else:
	#		audio_player.stream_paused = true
			#print("pause")

func play_open_sound():
	if not open_audio_player.playing:
		open_audio_player.play()
	
func play_close_sound():
	if not close_audio_player.playing:
		close_audio_player.play()


func _on_audio_stream_player_finished() -> void:
	play_sound()
