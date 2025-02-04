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
var stack_size: int

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