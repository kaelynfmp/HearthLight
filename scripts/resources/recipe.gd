@tool

@icon("res://resources/resource-icons/recipe.svg")

class_name Recipe

extends Resource

## Gadget this recipe uses
@export var gadget: Gadget:
	get():
		if Engine.is_editor_hint():
			var new_inputs:int = 1
			var new_outputs:int = 1
			if gadget != null:
				new_inputs = gadget.inputs
				new_outputs = gadget.outputs
			if new_inputs != inputs.size():
				# Resizing does not trigger the setter, so you need to resize a copied array,
				# and then set the entire array. Why.
				var temp_inputs:Array = inputs.duplicate()
				temp_inputs.resize(new_inputs)
				inputs = temp_inputs
			if new_outputs != outputs.size():
				# Resizing does not trigger the setter, so you need to resize a copied array,
				# and then set the entire array. Why.
				var temp_outputs:Array = outputs.duplicate()
				temp_outputs.resize(new_outputs)
				outputs = temp_outputs
		return gadget
## Inputs this recipe takes
@export var inputs: Array[Slot]:
	get():
		if Engine.is_editor_hint():
			for slot in inputs:
				if slot == null:
					slot = load("res://scripts/resources/slot.gd").new()
					if slot.item != null and !slot.changed.is_connected(slot_changed):
						slot.changed.connect(slot_changed)
				if slot.item != null and slot.item not in items:
					items.append(slot.item)
					add_gadget_filter(slot.item)
			var index: int = 0
			for item in items:
				var matching: Array = inputs.filter(func(slot): if slot != null: return slot.item == item)
				if matching.is_empty():
					items.remove_at(index)
					remove_gadget_filter(item)
				index += 1
		return inputs
	set(value):
		if Engine.is_editor_hint():
			for index in range(value.size()):
				if value[index] == null:
					# load an empty slot if array is ever appended
					value[index] = load("res://scripts/resources/slot.gd").new()
		inputs = value

var items: Array[Item] = []

## Outputs of this recipe
@export var outputs: Array[Slot]:
	get():
		if Engine.is_editor_hint():
			for slot in outputs:
				if slot.item != null and !slot.changed.is_connected(slot_changed):
					slot.changed.connect(slot_changed)
		return outputs
	set(value):
		if Engine.is_editor_hint():
			for index in range(value.size()):
				if value[index] == null:
					# load an empty slot if array is ever appended
					value[index] = load("res://scripts/resources/slot.gd").new()
		outputs = value
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

func slot_changed():
	ResourceSaver.save(self, get_path())
	take_over_path(get_path())
