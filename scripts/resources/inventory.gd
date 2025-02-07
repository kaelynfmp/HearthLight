@icon("res://resources/resource-icons/inventory.svg")

class_name Inventory

extends Resource

signal update

## Array of [Slot]s. Each slot contains the item, and how many of it per slot.
@export var slots: Array[Slot]

## Initialization of the default values
func _init(p_slots: Array[Slot] = []):
	slots = p_slots
	GameManager.inventory_changed.connect(on_inventory_changed)

func insert(item: Item, amount=1):
	var item_slots: Array = slots.filter(func(slot): return slot.item == item)
	var found: bool       = false
	if !item_slots.is_empty():
		for slot in item_slots:
			var remainder = slot.increment(amount)
			if (remainder == 0):
				found = true
				break
			else:
				amount = remainder
	if !found:
		var empty_slots: Array = slots.filter(func(slot): return slot.item == null)
		if !empty_slots.is_empty():
			for empty_slot in empty_slots:
				var remainder = empty_slot.initialize(item, amount)
				if (remainder == 0):
					break
				else:
					amount = remainder
		else:
			return false
	
	update.emit()
	return true
	
func on_inventory_changed():
	if GameManager.inventory:
		GameManager.add_inventory(self)
