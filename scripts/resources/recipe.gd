@tool

@icon("res://resources/resource-icons/recipe.svg")

class_name Recipe

extends Resource

## Gadget this recipe uses
@export var gadget: Gadget
## Inputs this recipe takes
@export var inputs: Array[Slot]:
	get():
		for slot in inputs:
			if slot == null:
				continue
			if slot.item != null and slot.item not in items:
				items.append(slot.item)
				add_gadget_filter(slot.item)
		var index: int = 0
		for item in items:
			var matching: Array = inputs.filter(func(slot): return slot.item == item)
			if matching.is_empty():
				items.remove_at(index)
				remove_gadget_filter(item)
			index += 1
		return inputs

var items: Array[Item] = []

## Outputs of this recipe
@export var outputs: Array[Slot]
## Processing time multiplier of this recipe
@export var processing_multiplier: float = 1.0

func _init(p_gadget: Gadget = null, p_inputs: Array[Slot] = [], p_outputs: Array[Slot] = [], p_processing_multiplier: float = 1.0):
	gadget = p_gadget
	inputs = p_inputs
	outputs = p_outputs
	processing_multiplier = p_processing_multiplier
	
func add_gadget_filter(item):
	if gadget != null:
		for gadget_slot in gadget.inventory.slots:
			if gadget_slot.locked:
				continue # that means its not an output
			if item in gadget_slot.item_filter:
				continue # it's already here, no change needed
			gadget_slot.item_filter.append(item)
			if Engine.is_editor_hint():
				var gadget_resource: Resource = ResourceLoader.load(gadget.get_path())
				gadget_resource.set("inventory", gadget.inventory)
				ResourceSaver.save(gadget, gadget.get_path())
				gadget.take_over_path(gadget.get_path())

func remove_gadget_filter(item):
	if gadget != null:
		for gadget_slot in gadget.inventory.slots:
			if gadget_slot.locked:
				continue # that means its not an output
			if item in gadget_slot.item_filter:
				gadget_slot.item_filter.remove_at(gadget_slot.item_filter.find(item))
				if Engine.is_editor_hint():
					var gadget_resource: Resource = ResourceLoader.load(gadget.get_path())
					gadget_resource.set("inventory", gadget.inventory)
					ResourceSaver.save(gadget, gadget.get_path())
					gadget.take_over_path(gadget.get_path())
