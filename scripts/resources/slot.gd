@tool

@icon("res://resources/resource-icons/slot.svg")

class_name Slot

extends Resource

signal update

## The [Item] that this slot represents. Can have multiple.
@export var item: Item :
	get:
		if item != null and item.max_stack != prev_max_stack:
			notify_property_list_changed()
			prev_max_stack = item.max_stack
		return item
	set(value):
		item = value
		notify_property_list_changed()

var prev_max_stack: int = 0

## The amount of items that are currently stored in this slot, to a max of [member Item.max_stack]
var quantity: int :
	set(value):
		# Validates to ensure an item can never get over its max
		if item != null:
			quantity = clamp(value, 0, item.max_stack)
			if quantity == 0:
				item = null
		else:
			quantity = 0

func _init(p_item = null, p_quantity = 0):
	item = p_item
	quantity = p_quantity
	
func _get_property_list() -> Array[Dictionary]:
	return [
		{
			name = "quantity",
			type = TYPE_INT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0, {max}, 1".format({"max": 0 if item == null else item.max_stack})
		},
	]
	
## Increments the amount of items in the slot by specified amount, default 1
func increment(amount: int = 1) -> int:
	var starting_value: int = quantity
	if item == null:
		return amount # nothing was put in
	var remainder: int      = starting_value + amount - item.max_stack
	quantity += amount
	
	update.emit()
	return max(remainder, 0)

## Decrements the amount of items in the slot by specified amount, default 1
func decrement(amount: int = 1) -> bool:
	if (amount > quantity):
		return true
	quantity -= amount
	update.emit()
	return item != null # returns whether the item still exists after decrementing
	
## Initializes the slot with an item and a stack size, default 1
func initialize(p_item: Item, p_quantity: int = 1):
	item = p_item
	quantity = p_quantity
	update.emit()
	if item == null:
		return 0
	return max(quantity - item.max_stack, 0)
