@icon("res://resources/resource-icons/inventory.svg")

class_name Inventory

extends Resource

signal update

## Array of [Slot]s. Each slot contains the item, and how many of it per slot.
@export var slots: Array[Slot]

## Initialization of the default values
func _init(p_slots: Array[Slot] = []):
	slots = p_slots

func insert(item: Item):
	var item_slots = slots.filter(func(slot): return slot.item == item)
	var found: bool = false
	if !item_slots.is_empty():
		for slot in item_slots:
			if slot.stack_size < item.max_stack:
				slot.stack_size += 1
				found = true
				break
	if !found:
		var empty_slots = slots.filter(func(slot): return slot.item == null)
		if !empty_slots.is_empty():
			empty_slots[0].item = item
			empty_slots[0].stack_size = 1
	
	update.emit()
