extends Node

signal inventory_changed

@export var inventory:bool = false

var cursor:Node2D

var inventories: Array[Inventory] = []

func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		change_inventory()

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
	
func get_cursor():
	return cursor
