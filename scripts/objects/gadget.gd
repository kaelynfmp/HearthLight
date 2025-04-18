extends StaticBody2D

class_name InWorldGadget

signal removing(layer_occupied_name:String, cell_pos:Vector2i)
signal item_at_location(cell_pos: Vector2i, item: Item)

@export var gadget_stats:Gadget
@onready var audio_player:AudioStreamPlayer2D = find_child("AudioStreamPlayer")
@onready var open_audio_player:AudioStreamPlayer2D = find_child("OpenAudioPlayer")
@onready var close_audio_player:AudioStreamPlayer2D = find_child("CloseAudioPlayer")
@onready var stop_audio_player:AudioStreamPlayer2D = find_child("StopAudioPlayer")
@onready var sprite:AnimatedSprite2D = find_child("Sprite")
@onready var valid_selection:CompressedTexture2D = load("res://scripts/shaders/close_enough_texture.tres")
@onready var invalid_selection:CompressedTexture2D = load("res://scripts/shaders/not_close_enough_texture.tres")
@export var inventory: Inventory
@export var is_holding: bool = false
@export var has_power_from_generator = false
@export var total_power:float = 0.0
@export var power_per_coal = 10

# Marker to remove when gadget picked up
@onready var marker: Node2D = get_node("/root/Room/Tilemap/TileLayers/Marker2")

# Teleporter input
var mounted_gadget: InWorldGadget

# Array of target teleporters
var target_list: Array[InWorldGadget]
# Round-robin distribution, so every second increase this target index to match with target_list
var target_index = 0

var max_power:int = 100
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
var rear_gadget: InWorldGadget
var front_gadget: InWorldGadget
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
var gadgets_used_this_generator = []
var nearby_cyber_generator: StaticBody2D
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
		slot.bypass_stack = gadget_stats.inventory.slots[i].bypass_stack
		inventory.slots.append(slot)
	for i in range(num_outputs):
		var slot: Slot = Slot.new()
		slot.item = null
		slot.locked = true
		slot.item_filter = gadget_stats.inventory.slots[num_inputs + i].item_filter
		slot.bypass_stack = gadget_stats.inventory.slots[num_inputs + i].bypass_stack
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
	if gadget_stats.name == "Teleporter":
		mount_to_inventory()
		GameManager.add_teleporter(self)
	rotate_sprite()
	if gadget_stats.name == "Conveyor Belt":
		collision_layer = 2
		collision_mask = 2
	audio_player.set_stream(gadget_stats.ambient_sound)
	stop_audio_player.set_stream(gadget_stats.stop_sound)
	open_audio_player.set_stream(gadget_stats.open_sound)
	close_audio_player.set_stream(gadget_stats.close_sound)
	update_recipes()
	GameManager.update_recipes.connect(update_recipes)
	GameManager.teleporter_removed.connect(remove_teleporter)
	notification = find_child("Notification")
	
func check_for_nearby_generator(delta: float):
	if GameManager.has_cyber_generator:
		nearby_cyber_generator = GameManager.cyber_generator
		return true
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
	
func mount_to_inventory():
	var target_pos: Vector2i = cell_pos + direction_vector[(direction + 2) % 4]
	if GameManager.room_map[target_pos[0] + 6][target_pos[1] + 5] != null:
		var target_gadget = GameManager.room_map[target_pos[0] + 6][target_pos[1] + 5]
		if target_gadget.gadget_stats.name == "Teleporter":
			mounted_gadget = null
		else:
			mounted_gadget = target_gadget
			
func push_to_mounted_gadget():
	if mounted_gadget != null:
		var slots = inventory.slots
		var pushed_item = null
		for slot in slots:
			if slot.item != null:
				pushed_item = slot.item
				mounted_gadget.inventory.insert(pushed_item, 1, false)
				break
		if pushed_item != null:
			inventory.remove_items(pushed_item, 1, false)

func _physics_process(delta: float) -> void:
	if GameManager.computer_visible and not GameManager.time_final: return
	if not gadget_stats.produces:
		return
	if GameManager.gadget == null:
		primitive_selected = false
	if gadget_stats.name == "Teleporter":
		push_to_mounted_gadget()
	check_for_valid_recipe()
	if gadget_stats.age > GameManager.Age.PRIMITIVE and not is_generator:
		has_power_from_generator = check_for_nearby_generator(delta)
	if is_generator:
		has_power = total_power > 0 or (is_cyber_generator)
		if not is_cyber_generator:
			if prev_power != total_power:
				prev_power = total_power
				if not AudioManager.active_gadgets[gadget_stats.sound_string].has(self):
					AudioManager.active_gadgets[gadget_stats.sound_string][self] = true
			else:
				if AudioManager.active_gadgets[gadget_stats.sound_string].has(self):
					AudioManager.active_gadgets[gadget_stats.sound_string].erase(self)
		else:
			if gadgets_used_this_generator.size() > 0:
				if not AudioManager.active_gadgets[gadget_stats.sound_string].has(self):
					AudioManager.active_gadgets[gadget_stats.sound_string][self] = true
			else:
				if AudioManager.active_gadgets[gadget_stats.sound_string].has(self):
					AudioManager.active_gadgets[gadget_stats.sound_string].erase(self)
	if !disabled and !progressing or (!progressing and selected_recipe != null) and not GameManager.sleeping:
		if gadget_stats.name in ["Conveyor Belt", "Teleporter"]:
			if gadget_stats.name != "Teleporter" or has_power_from_generator:
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
		primitive_selected or is_generator) or gadget_stats.name == "Teleporter"):
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
			if not gadget_stats.name in ["Conveyor Belt", "Teleporter"]:
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
		if slot.bypass_stack:
			return true
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
			
func add_teleporter(teleporter:InWorldGadget):
	target_list.append(teleporter)
	GameManager.gadget_changed.emit()
	
func remove_teleporter(teleporter:InWorldGadget):
	var temp_list:Array[InWorldGadget] = target_list.duplicate()
	target_list.erase(teleporter)
	if temp_list != target_list: # If list was changed, emit the signal
		GameManager.gadget_changed.emit()
	
func _process(_delta: float) -> void:
	rotate_sprite()
	# Test the code
	if gadget_stats.name == "Teleporter":
		mount_to_inventory()	
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
	if gadget_stats.name == "Teleporter":
		if len(target_list) > 0:
			start_progression_transport()
	else:
		var rear_gadget_pos: Vector2i = cell_pos + direction_vector[direction]
		if (GameManager.room_map[rear_gadget_pos[0] + 6][rear_gadget_pos[1] + 5] != null):
			rear_gadget = GameManager.room_map[rear_gadget_pos[0] + 6][rear_gadget_pos[1] + 5]
			if rear_gadget != null and rear_gadget.gadget_stats.name != "Conveyor Belt":
				start_progression_transport()
			
func start_progression_transport():
	if gadget_stats.name == "Conveyor Belt":
		pull_inventory()
	progressing = true
	
func finish_transport():
	if gadget_stats.name == "Teleporter":
		pull_inventory()
	cancel_processing()
	

func pull_from_gadget(selected_gadget: InWorldGadget) -> bool:
	var worked = false
	var is_conveyer_belt:bool = gadget_stats.name == "Conveyor Belt"
	var is_teleporter:bool = gadget_stats.name == "Teleporter"
	var selected_inventory: Inventory = selected_gadget.inventory
	var selected_slots = selected_inventory.slots.filter(func(slot): 
		return slot.locked)
	if selected_gadget.gadget_stats.name == "Storage":
		selected_slots = selected_inventory.slots.filter(func(slot): return !slot.locked)
	if is_conveyer_belt:
		for slot in selected_slots:
			if slot.item != null:
				var item: Item = slot.item
				if selected_gadget.gadget_stats.name != "Conveyor Belt":
						item_at_location.emit(cell_pos, item)
				selected_inventory.remove_items(item, 1, slot.locked)
				worked = true
				break
	else:
		if is_teleporter:
			# Teleporter insta-clears out an entire inventory
			# Sends directly to the mounted gadget to avoid race conditions
			# If something is somehow in the teleporter, however, it will still push properly
			for slot in selected_slots:
				if slot.item == null: continue
				if target_list.size() > 1:
					var slot_attempts:int = 0
					# Skip while loop if it would not be possible to empty this slot even a little
					# Expensive, but less expensive than running a failing while loop 100 times
					var mega_inventory:Inventory = Inventory.new()
					for target in target_list:
						if target.mounted_gadget != null:
							mega_inventory.slots.append_array(target.mounted_gadget.inventory.slots)
					if mega_inventory.can_insert(slot.item, slot.quantity) == slot.quantity:
						continue
					while slot_attempts < 100 and slot.quantity > 0:
						# Clear out the slot
						var destination_gadget:InWorldGadget = target_list[target_index]
						if target_list[target_index].mounted_gadget != null:
							if destination_gadget != null and destination_gadget.mounted_gadget.inventory.can_insert(slot.item) == 0:
								destination_gadget.mounted_gadget.inventory.insert(slot.item)
								slot.decrement()
								worked = true
						target_index += 1
						if target_index >= len(target_list):
							target_index = 0
						slot_attempts += 1
				else:
					if target_list[0].mounted_gadget == null: continue
					var remainder:int = target_list[0].mounted_gadget.inventory.can_insert(slot.item, slot.quantity)
					target_list[0].mounted_gadget.inventory.insert(slot.item, slot.quantity)
					if remainder < slot.quantity:
						worked = true
					slot.decrement(slot.quantity - remainder)
					
	return worked
	


func pull_inventory():
	if gadget_stats.name == "Teleporter" and mounted_gadget != null and not target_list.is_empty():
		var prev_inventory_slots = mounted_gadget.inventory.slots.duplicate()
		if pull_from_gadget(mounted_gadget):
			AudioManager.play_teleport_noise()
	if GameManager.item_map[cell_pos[0] + 6][cell_pos[1] + 5] == null: 
		if rear_gadget:
			pull_from_gadget(rear_gadget)

func update_recipes():
	recipes.clear()
	for recipe:Recipe in GameManager.recipes:
		if recipe.gadget == gadget_stats:
			recipes.append(recipe)
		
func check_for_valid_recipe() -> void:
	if is_generator and total_power >= max_power:
		total_power = max_power
		selected_recipe = null
		return
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

func start_progression() -> void:
	if GameManager.sleeping: return
	recipe_taken = false
	if nearby_cyber_generator != null:
		nearby_cyber_generator.gadgets_used_this_generator.append(self)
	if is_generator:
		recipe_take()
	progressing = true
	play_sound()
	if not is_generator:
		if gadget_stats.sound_string != null and gadget_stats.sound_string != "":
			# 'True' is arbitrary value, this is a dictionary only to preserve uniqueness
			AudioManager.active_gadgets[gadget_stats.sound_string][self] = true
	
func recipe_take() -> void:
	if GameManager.sleeping: return
	for input in selected_recipe.inputs:
		# We know that the recipe is valid, so we can just remove willy nilly
		for slot in inventory.slots.filter(func(slot): return !slot.locked):
			if slot.item != null and slot.item.name == input.item.name:
				inventory.remove_items(slot.item, input.quantity)
	recipe_taken = true

func finish_recipe() -> void:
	if GameManager.sleeping: return
	if not is_generator:
		recipe_take()
		for output in selected_recipe.outputs:
			inventory.insert(output.item, output.quantity, true)
	cancel_processing()
	
func cancel_processing() -> void:
	if GameManager.sleeping: return
	progress = 0.0
	progressing = false
	audio_player.stop()
	if not stop_audio_player.playing and not primitive_selected and gadget_stats.name != "Teleporter":
		stop_audio_player.play()
	if nearby_cyber_generator != null:
		nearby_cyber_generator.gadgets_used_this_generator.erase(self)
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
			if gadget_stats.name in ["Generator", "Universal Generator"]:
				marker.visible = false
			if gadget_stats.name == "Universal Generator":
				GameManager.has_cyber_generator = false
				GameManager.cyber_generator = null
			elif gadget_stats.name == "Teleporter":
				GameManager.remove_teleporter(self)
			for slot in inventory.slots:
				# Send it all away to any open inventories
				GameManager.send_to_inventory(slot)
			if gadget_stats.age > Gadget.Age.PRIMITIVE and not gadget_stats.name in ["Computer", "Conveyor Belt", "Storage", "Teleporter"]:				
				AudioManager.call_deferred("remove_audio", gadget_stats.sound_string, self)
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
