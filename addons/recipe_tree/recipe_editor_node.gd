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
			gadget_node.cleared.connect(clear_gadget_node)
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
					recipe.inputs[index].item = item_node.item
				if item_node != null:
					if !item_node.cleared.is_connected(clear_input_item_node):
						item_node.cleared.connect(clear_input_item_node)
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
				if !item_node.cleared.is_connected(clear_output_item_node):
					item_node.cleared.connect(clear_output_item_node)
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
	gadget_node.cleared.disconnect(clear_gadget_node)
	gadget_node = null
	# We also clear all of the item nodes, as clearing the gadget removes all inputs and outputs
	for item_node in input_item_nodes:
		item_node.cleared.disconnect(clear_input_item_node)
	input_item_nodes.clear()
	for item_node in output_item_nodes:
		item_node.cleared.disconnect(clear_output_item_node)
	output_item_nodes.clear()
	
func clear_input_item_node(item_node) -> void:
	input_item_nodes[input_item_nodes.find(item_node)].cleared.disconnect(clear_input_item_node)
	input_item_nodes.remove_at(input_item_nodes.find(item_node))

func clear_output_item_node(item_node) -> void:
	output_item_nodes[output_item_nodes.find(item_node)].cleared.disconnect(clear_output_item_node)
	output_item_nodes.remove_at(output_item_nodes.find(item_node))
	
func save_recipe():
	if recipe != null:
		ResourceSaver.save(recipe, recipe.get_path())
		recipe.take_over_path(recipe.get_path())
	