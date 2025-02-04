@tool

@icon("res://resources/resource-icons/slot.svg")

class_name Slot

extends Resource

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
var stack_size: int :
	set(value):
		# Validates to ensure an item can never get over its max
		if item != null:
			stack_size = clamp(value, 0, item.max_stack)

func _init(p_item = null, p_stack_size = 0):
	item = p_item
	stack_size = p_stack_size
	
func _get_property_list() -> Array[Dictionary]:
	return [
		{
			name = "stack_size",
			type = TYPE_INT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0, {max}, 1".format({"max": 0 if item == null else item.max_stack})
		},
	]
	
## Increments the amount of items in the slot by specified amount, default 1
func increment(amount: int = 1) -> bool:
	var starting_value: int = stack_size
	stack_size += amount
	return starting_value != stack_size
	
## Initializes the slot with an item and a stack size, default 1
func initialize(p_item: Item, p_stack_size: int = 1):
	item = p_item
	stack_size = p_stack_size