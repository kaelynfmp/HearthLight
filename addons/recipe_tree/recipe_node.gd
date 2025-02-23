@tool
extends GraphNode

@onready var recipe_node:RecipeEditorNode
signal moved(to:Vector2, recipe_node:RecipeEditorNode)

func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	if recipe_node != null:
		if recipe_node.recipe == null:
			return
		var contained:HBoxContainer = find_child("Contained", true)
		if contained != null:
			var input_children:Array = contained.get_children().filter(func(child): return "Input" in child.get_name())
			if recipe_node.recipe.inputs.size() != input_children.size():
				# If the amount of children that are contained (only accounting for ones that have 'input' in the name) aren't
				# equal to the correct amount of inputs in the recipe
				for child:PanelContainer in input_children:
					contained.remove_child(child)
				var inputs:Array[Slot] = recipe_node.recipe.inputs
				for index in range(inputs.size()):
					var input:Slot = inputs[index]
					var new_slot:PanelContainer = load("res://scenes/inventory/input_slot.tscn").instantiate()
					new_slot.set_slot(input)
					new_slot.update()
					new_slot.set_name("InputSlot" + str(index))
					if inputs.size() >= 3:
						if index % 2 == 1:
							new_slot.size_flags_vertical = SIZE_SHRINK_BEGIN
						else:
							new_slot.size_flags_vertical = SIZE_SHRINK_END
					else:
						new_slot.size_flags_vertical = SIZE_SHRINK_CENTER
					contained.add_child(new_slot)
					contained.move_child(new_slot, index)
		var output_children:Array = contained.get_children().filter(func(child): return "Output" in child.get_name())
		if recipe_node.recipe.outputs.size() != output_children.size():
			# If the amount of children that are contained (only accounting for ones that have 'input' in the name) aren't
			# equal to the correct amount of inputs in the recipe
			for child:PanelContainer in output_children:
				contained.remove_child(child)
			var starting_index:int = contained.get_child_count()
			var outputs:Array[Slot] = recipe_node.recipe.outputs
			for index in range(outputs.size()):
				var output:Slot = outputs[index]
				var new_slot:PanelContainer = load("res://scenes/inventory/output_slot.tscn").instantiate()
				new_slot.set_slot(output)
				new_slot.update()
				new_slot.set_name("OutputSlot" + str(index))
				if outputs.size() >= 3:
					if index % 2 == 1:
						new_slot.size_flags_vertical = SIZE_SHRINK_BEGIN
					else:
						new_slot.size_flags_vertical = SIZE_SHRINK_END
				else:
					new_slot.size_flags_vertical = SIZE_SHRINK_CENTER
				contained.add_child(new_slot)
				contained.move_child(new_slot, starting_index + index)
		if recipe_node.recipe.gadget != null:
			var gadget_slot:PanelContainer = find_child("GadgetSlot", true)
			if gadget_slot != null:
				if gadget_slot.slot == null or gadget_slot.slot.item != recipe_node.recipe.gadget.item:
					var new_slot = load("res://scripts/resources/slot.gd").new()
					new_slot.item = recipe_node.recipe.gadget.item
					gadget_slot.set_slot(new_slot)
					gadget_slot.update()
						
func _on_dragged(from:Vector2, to:Vector2) -> void:
	moved.emit(to, recipe_node)
