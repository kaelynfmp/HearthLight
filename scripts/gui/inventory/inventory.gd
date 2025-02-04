extends Control

@onready var inventory: Inventory = preload("res://resources/character/inventory.tres")
@onready var slots: Array = $Background/Slots.get_children()


var is_open: bool = false

func _ready() -> void:
	inventory.update.connect(update_slots)
	update_slots()
	close()
	
func update_slots():
	for i in range(min(inventory.slots.size(), slots.size())):
		slots[i].update(inventory.slots[i])
	
func _process(_delta: float):
	if Input.is_action_just_pressed("inventory"):
		close() if is_open else open()

func open():
	visible = true
	is_open = true

func close():
	visible = false
	is_open = false
