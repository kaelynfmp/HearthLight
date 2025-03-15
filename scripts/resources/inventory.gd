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

## Attempts to insert [Item]s, going into the earliest available [Slot]s
func insert(item: Item, amount=1, locked_only=false) -> int:
	var item_slots: Array = slots.filter(func(slot): return (slot.item == item and (!slot.locked and !locked_only) or (slot.locked and locked_only)))
	if !item_slots.is_empty():
		for slot in item_slots:
			if !locked_only or slot.locked:
				var remainder = slot.increment(amount, locked_only)
				amount = remainder
				if (amount == 0):
					break
	if amount > 0:
		var empty_slots: Array = slots.filter(func(slot): return (slot.item == null and (!slot.locked and !locked_only) or (slot.locked and locked_only)))
		if !empty_slots.is_empty():
			for empty_slot in empty_slots:
				if !locked_only or empty_slot.locked:
					var remainder = empty_slot.initialize(item, amount, locked_only)
					amount = remainder
					if (amount == 0):
						break
		
	changed.emit()
	return amount
	
## Returns how many [Item]s can be sent to the inventory
func can_insert(item: Item, amount=1, locked_only=false) -> int:
	var item_slots: Array = slots.filter(func(slot): 
		return (slot.item == item and (!slot.locked and !locked_only) or (slot.locked and locked_only)))
	if !item_slots.is_empty():
		for slot in item_slots:
			if !locked_only or slot.locked:
				if slot.bypass_stack:
					amount = 0
					break
				var remainder = max(0, amount - slot.quantity)
				if (remainder == 0):
					amount = 0
					break
				else:
					amount = remainder
	if amount > 0:
		var empty_slots: Array = slots.filter(func(slot): return (slot.item == null and (!slot.locked and !locked_only) or (slot.locked and locked_only)))
		if !empty_slots.is_empty():
			for empty_slot:Slot in empty_slots:
				if !locked_only or empty_slot.locked:
					if empty_slot.bypass_stack:
						amount = 0
						break
					else:
						amount = max(0, amount - item.max_stack)
						if amount == 0:
							break
		
	return amount
	

## Attempts to remove a specified [int] quantity of an [Item] from the inventory, and returns true if it succeeded, false otherwise
func remove_items(item: Item, quantity:int, locked_only=false) -> bool:
	if get_item_quantity(item) < quantity:
		return false

	var temp_quantity:int = 0
	for slot in slots:
		if slot.item == item and (!locked_only or slot.locked):
			var item_quantity:int = slot.quantity
			var remaining:int = quantity - temp_quantity
			if remaining <= item_quantity:
				item_quantity = remaining
			if slot.decrement(item_quantity):
				temp_quantity += item_quantity
				if temp_quantity == quantity:
					return true
	return false	

## Returns the [int] quantity of an [Item] in the entire inventory, cumulative, with an optional parameter to check 
## if the [Slot] is locked before pooling it
func get_item_quantity(item: Item, locked_check=false) -> int:
	var quantity:int = 0
	for slot in slots:
		if slot.item == item and (!locked_check or !slot.locked):
			quantity += slot.quantity

	return quantity
			
