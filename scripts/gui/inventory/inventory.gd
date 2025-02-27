extends Control

@onready var inventory: Inventory = preload("res://resources/character/inventory.tres")

@export var slide_in_speed:float

var is_open: bool = false
var starting_x:float
var max_pos:float

func _ready() -> void:
	starting_x = position.x
	max_pos = get_viewport_rect().size.x + ($Background.size.x * scale.x) + 10
	set_position(Vector2(max_pos, position.y))
	inventory.changed.connect(update_slots)
	update_slots()
	GameManager.inventory_open_state_changed.connect(on_inventory_open_state_changed)
	
func update_slots():
	var slots = $Background/Slots.get_children()
	for i in range(min(inventory.slots.size(), slots.size())):
		slots[i].set_slot(inventory.slots[i])
	
func _process(delta: float):
	set_position(Vector2(lerp(position.x, starting_x if is_open else max_pos, slide_in_speed * delta), position.y))
	
	
func on_inventory_open_state_changed():
	is_open = !is_open
