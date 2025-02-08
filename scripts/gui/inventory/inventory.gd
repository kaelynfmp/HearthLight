extends Control

@onready var inventory: Inventory = preload("res://resources/character/inventory.tres")
@onready var slots: Array = $Background/Slots.get_children()

var is_open: bool = false

func _ready() -> void:
	inventory.update.connect(update_slots)
	update_slots()
	GameManager.inventory_changed.connect(on_inventory_changed)
	
func update_slots():
	for i in range(min(inventory.slots.size(), slots.size())):
		slots[i].set_slot(inventory.slots[i])
	
func _process(_delta: float):
	visible = is_open
	
func on_inventory_changed():
	is_open = !is_open