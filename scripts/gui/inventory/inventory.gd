extends Control

@onready var inventory: Inventory = preload("res://resources/character/inventory.tres")

var is_open:bool

func _ready() -> void:
	inventory.changed.connect(update_slots)
	update_slots()
	GameManager.inventory_open_state_changed.connect(on_inventory_open_state_changed)
	
func update_slots():
	var slots = $Background/Slots.get_children()
	for i in range(min(inventory.slots.size(), slots.size())):
		slots[i].set_slot(inventory.slots[i])
	
func on_inventory_open_state_changed():
	is_open = !is_open
