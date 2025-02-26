@tool
class_name RecipeEditorNode

extends Resource

@export var recipe:Recipe
@export var x:int
@export var y:int
@export var gadget_node:GadgetEditorNode :
	set(value):
		gadget_node = value
		if gadget_node != null:
			if recipe != null:
				recipe.gadget = gadget_node.gadget
		else:
			if recipe != null:
				recipe.gadget = null
		save_recipe()
		changed.emit()
var prev_input_item_nodes_size:int = 0
@export var input_item_nodes:Array[ItemEditorNode]:
	get:
		if prev_input_item_nodes_size != input_item_nodes.size():
			prev_input_item_nodes_size = input_item_nodes.size()
			changed.emit()
			if recipe != null:
				for input:Slot in recipe.inputs:
					input.item = null
			for index in range(input_item_nodes.size()):
				var item_node:ItemEditorNode = input_item_nodes[index]
				if recipe != null:
					if recipe.inputs.size() > index:
						recipe.inputs[index].item = item_node.item
			save_recipe()
		return input_item_nodes
var prev_output_item_nodes_size:int = 0
@export var output_item_nodes:Array[ItemEditorNode]:
	get:
		if prev_output_item_nodes_size != output_item_nodes.size():
			prev_output_item_nodes_size = output_item_nodes.size()
			if recipe != null:
				for output:Slot in recipe.outputs:
					output.item = null
			for index in range(output_item_nodes.size()):
				var item_node:ItemEditorNode = output_item_nodes[index]
				if recipe != null:
					recipe.outputs[index].item = item_node.item
			save_recipe()
		return output_item_nodes

func _init(p_recipe:Recipe = null, p_x:int = 0, p_y:int = 0, p_gadget_node:GadgetEditorNode = null, p_input_item_nodes:Array[ItemEditorNode] = [], p_output_item_nodes:Array[ItemEditorNode] = []):
	recipe = p_recipe
	x = p_x
	y = p_y
	gadget_node = p_gadget_node
	input_item_nodes = p_input_item_nodes
	output_item_nodes = p_output_item_nodes
	
func clear_gadget_node() -> void:
	gadget_node = null
	# We also clear all of the item nodes, as clearing the gadget removes all inputs and outputs
	var clear_input_nodes:Array
	for index in range(input_item_nodes.size()):
		clear_input_nodes.append(index)

	for index in range(clear_input_nodes.size()):
		clear_input_item_node(input_item_nodes[clear_input_nodes[index] - index])

	var clear_output_nodes:Array
	for index in range(output_item_nodes.size()):
		clear_output_nodes.append(index)

	for index in range(clear_output_nodes.size()):
		clear_output_item_node(output_item_nodes[clear_output_nodes[index] - index])
	
func clear_input_item_node(item_node) -> void:
	input_item_nodes.remove_at(input_item_nodes.find(item_node))

func clear_output_item_node(item_node) -> void:
	output_item_nodes.remove_at(output_item_nodes.find(item_node))
	
func save_recipe():
	if recipe != null:
		ResourceSaver.save(recipe, recipe.get_path())
		recipe.take_over_path(recipe.get_path())
	