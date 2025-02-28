extends StaticBody2D

signal removing(layer_occupied_name:String, cell_pos:Vector2i)

@export var gadget_stats:Gadget
@onready var audio_player:AudioStreamPlayer2D = find_child("AudioStreamPlayer")

@onready var sprite:Sprite2D = find_child("Sprite")
@onready var valid_selection:CompressedTexture2D = load("res://scripts/shaders/close_enough_texture.tres")
@onready var invalid_selection:CompressedTexture2D = load("res://scripts/shaders/not_close_enough_texture.tres")

@export var inventory: Inventory

@export var is_holding: bool = false

var character: Node2D

var base_layer: Node2D

var age:int

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	inventory = gadget_stats.inventory.duplicate()
	character = get_parent().get_parent().get_parent().find_child("Character")
	base_layer = get_parent()
	age = gadget_stats.age
	sprite.texture = gadget_stats.texture
	audio_player.set_stream(gadget_stats.ambient_sound)
	update_recipes()
	GameManager.update_recipes.connect(update_recipes)

func _physics_process(delta: float) -> void:
	if !progressing or (!progressing and selected_recipe != null):
		var checked_recipe:Recipe = check_for_valid_recipe()
		if checked_recipe != null:
			do_recipe(checked_recipe)
	else:
		var change_rate:float = delta / (gadget_stats.process_time * selected_recipe.processing_multiplier)
		if age > GameManager.Age.PRIMITIVE or primitive_selected:
			progress += change_rate
		else:
			progress -= change_rate
		if progress >= 1:
			finish_recipe()
		elif progress <= 0:
			cancel_processing()
	
func _process(_delta: float) -> void:
	if hovered:
		sprite.material.set("shader_parameter/textureScale", Vector2.ONE)
		if detect_nearby():
			sprite.material.set("shader_parameter/scrollingTexture", valid_selection)
		else:
			sprite.material.set("shader_parameter/scrollingTexture", invalid_selection)
	else:
		sprite.material.set("shader_parameter/textureScale", Vector2.ZERO)
		pass
		
func update_recipes():
	recipes.clear()
	for recipe:Recipe in GameManager.recipes:
		if recipe.gadget == gadget_stats:
			recipes.append(recipe)
		
func check_for_valid_recipe() -> Recipe:
	for recipe in recipes:
		var inputs:Array[Slot] = inventory.slots.filter(func(slot): return !slot.locked)
		var valid:int = 0
		for input in recipe.inputs:
			if inventory.get_item_quantity(input.item, true) >= input.quantity:
				valid += 1
		if valid == inputs.size():
			# valid!
			return recipe
	selected_recipe = null
	return null
	
func do_recipe(recipe:Recipe):
	selected_recipe = recipe
	if age > GameManager.Age.PRIMITIVE or primitive_selected:
		start_progression()

func start_progression():
	recipe_taken = false
	progressing = true
	play_sound()
	
func recipe_take():
	for input in selected_recipe.inputs:
		# We know that the recipe is valid, so we can just remove willy nilly
		inventory.remove_items(input.item, input.quantity)
	recipe_taken = true

func finish_recipe():
	recipe_take()
	for output in selected_recipe.outputs:
		inventory.insert(output.item, output.quantity, true)
	cancel_processing()
	
func cancel_processing():
	progress = 0.0
	progressing = false
	audio_player.stop()
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
		if GameManager.pickup_gadget(gadget_stats):
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


func _on_audio_stream_player_finished() -> void:
	play_sound()
