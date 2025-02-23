extends StaticBody2D

@onready var gadget_stats = load("res://resources/gadgets/wheel.tres")

@export var output_inventory: Inventory

@export var is_holding: bool = false

var character: Node2D

var base_layer: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	character = get_parent().get_parent().get_parent().find_child("Character")
	base_layer = get_parent()
	$Sprite2D.texture = gadget_stats.texture
	$Timer.wait_time = gadget_stats.process_time
	$Timer.timeout.connect(add_item_to_inventory)
	$TextureProgressBar.visible = false
	$TextureProgressBar.value = 0
	$TextureProgressBar.max_value = $Timer.wait_time


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_holding:
		$TextureProgressBar.value += 1*delta
	else:
		$TextureProgressBar.value -= .8*delta
		
	if $TextureProgressBar.value >= $TextureProgressBar.max_value:
		add_item_to_inventory()
		$TextureProgressBar.value = 0
	#$TextureProgressBar.value = 100 - ($Timer.time_left / $Timer.wait_time) * 100
	
func add_item_to_inventory() -> void:
	var item: Item = load("res://resources/items/cotton.tres")
	collect(item)
		
## 'Collects' a given item, placing it into the inventory on the nearest open slot
func collect(item: Item):
	character.inventory.insert(item)

# Temporary highlight
func _on_mouse_entered() -> void:
	$TextureProgressBar.visible = true
	$Sprite2D.self_modulate = Color(1.0, 1.0, 1.0, 0.5)

func _on_mouse_exited() -> void:
	$TextureProgressBar.visible = false
	$Sprite2D.self_modulate = Color(1.0, 1.0, 1.0, 1.0) # Replace with function body.

func detect_nearby() -> bool:
	var character_cell_position: Vector2 = base_layer.local_to_map(character.global_position)
	var gadget_cell_position: Vector2 = base_layer.local_to_map(global_position)
	return character_cell_position.distance_squared_to(gadget_cell_position) <= 2.0

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if detect_nearby() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: # Replace with function body.
		is_holding = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
		is_holding = false
