@tool

@icon("res://resources/resource-icons/slot.svg")

class_name Slot

extends Resource

## The [Item] that this slot represents. Can have multiple.
@export var item: Item :
	get:
		if Engine.is_editor_hint() and item != null:
			if !item.changed.is_connected(item_changed):
				item.changed.connect(item_changed)
		if item != null and item.max_stack != prev_max_stack:
			notify_property_list_changed()
			prev_max_stack = item.max_stack
			changed.emit()
		return item
	set(value):
		item = value
		if value == null:
			decrement(quantity)
		else:
			quantity = max(quantity, 1)
		changed.emit()
		notify_property_list_changed()

## Whether or not this slot is locked to inputs.
## NOTE: This slot can still be taken from, but not input into.
@export var locked: bool

## Filter of items that can only be in this slot
@export var item_filter: Array[Item]

## Whether or not the items max stack limit is bypassed
@export var bypass_stack: bool

var prev_max_stack: int = 0

## The amount of items that are currently stored in this slot, to a max of [member Item.max_stack]
var quantity: int :
	set(value):
		# Validates to ensure an item can never get over its max
		if item != null:
			quantity = clamp(value, 0, item.max_stack if not bypass_stack else GameManager.Items.MAX)
			if quantity == 0:
				item = null
		else:
			if !Engine.is_editor_hint():
				quantity = 0
		changed.emit()

func _init(p_item: Item = null, p_quantity: int = 0, p_bypass_stack:bool = false, p_locked: bool = false, p_item_filter: Array[Item] = []):
	item = p_item
	quantity = p_quantity
	bypass_stack = p_bypass_stack
	locked = p_locked
	item_filter = p_item_filter
	
func _get_property_list() -> Array[Dictionary]:
	return [
		{
			name = "quantity",
			type = TYPE_INT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0, {max}, 1".format({"max": 0 if item == null else (item.max_stack if not bypass_stack else GameManager.Items.MAX)})
		}
	]
	
## Increments the amount of items in the slot by specified amount, default 1
func increment(amount: int = 1, bypass: bool = false) -> int:
	if can_insert() or bypass:
		var starting_value: int = quantity
		if item == null:
			return amount # nothing was put in
		var remainder: int = starting_value + amount - item.max_stack
		quantity += amount
		
		changed.emit()
		return max(remainder, 0)
	return amount

## Decrements the amount of items in the slot by specified amount, default 1
func decrement(amount: int = 1) -> bool:
	if (amount > quantity):
		return true
	quantity -= amount
	changed.emit()
	return item != null # returns whether the item still exists after decrementing
	
## Initializes the slot with an item and a stack size, default 1
func initialize(p_item: Item, p_quantity: int = 1, bypass: bool = false) -> int:
	if can_insert(p_item) or bypass:
		item = p_item
		quantity = p_quantity
		changed.emit()
		if item == null:
			return 0
		# Return attempted quantity minus actual quantity, since it'll go to its stack limit
		return max(p_quantity - quantity, 0)
	return p_quantity
	
## Whether the item is either locked or the item is not in the filter
func can_insert(check_item: Item = null) -> bool:
	if check_item == null: # You can always insert nothing into a slot
		return true
	if locked:
		return false
	if check_item != null:
		if !item_filter.is_empty():
			return (check_item in item_filter)
		return true
	return true
	
func item_changed():
	changed.emit()
