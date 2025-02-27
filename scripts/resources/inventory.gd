@tool
@icon("res://resources/resource-icons/inventory.svg")

class_name Inventory

extends Resource

## Array of [Slot]s. Each slot contains the item, and how many of it per slot.
@export var slots: Array[Slot]:
	set(value):
		for index in range(value.size()):
			# load an empty slot if array is ever appended
			if value[index] == null:
				value[index] = load("res://scripts/resources/slot.gd").new()
		slots = value

## Initialization of the default values
func _init(p_slots: Array[Slot] = []):
	slots = p_slots
	if !Engine.is_editor_hint():
		GameManager.inventory_open_state_changed.connect(on_inventory_open_state_changed)

## Attempts to insert [Item]s, going into the earliest available [Slot]s
func insert(item: Item, amount=1) -> bool:
	var item_slots: Array = slots.filter(func(slot): return (slot.item == item and not slot.locked))
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
		var empty_slots: Array = slots.filter(func(slot): return (slot.item == null and not slot.locked))
		if !empty_slots.is_empty():
			for empty_slot in empty_slots:
				var remainder = empty_slot.initialize(item, amount)
				if (remainder == 0):
					break
				else:
					amount = remainder
		else:
			return false
	
	changed.emit()
	return true
	
func on_inventory_open_state_changed():
	if !Engine.is_editor_hint():
		if GameManager.inventory:
			GameManager.add_inventory(self)
