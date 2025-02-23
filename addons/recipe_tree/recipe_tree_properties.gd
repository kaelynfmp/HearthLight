class_name RecipeTreeProperties

extends Resource

@export var recipe_nodes:Array[RecipeEditorNode]
@export var gadget_nodes:Array[GadgetEditorNode]
@export var item_nodes:Array[ItemEditorNode]

func _init(p_recipe_nodes:Array[RecipeEditorNode] = [], p_gadget_nodes:Array[GadgetEditorNode] = [], p_item_nodes:Array[ItemEditorNode] = []):
	recipe_nodes = p_recipe_nodes
	gadget_nodes = p_gadget_nodes
	item_nodes = p_item_nodes
