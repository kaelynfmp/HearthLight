@tool
extends EditorPlugin

var control
var recipe_strings:PackedStringArray
var recipes:Array[Recipe]
var gadget_strings:PackedStringArray
var gadgets:Array[Gadget]
var item_strings:PackedStringArray
var items:Array[Item]
var properties:RecipeTreeProperties = preload("res://addons/recipe_tree/recipe_tree_properties.tres")
enum TYPE {
	RECIPE, GADGET, ITEM
}
@onready var graph_edit:GraphEdit
@onready var recipe_node:PackedScene
@onready var gadget_node:PackedScene
@onready var item_node:PackedScene


func _enter_tree() -> void:
	control = preload("res://addons/recipe_tree/recipe_tree.tscn").instantiate()
	add_control_to_container(CONTAINER_CANVAS_EDITOR_SIDE_RIGHT, control)
	graph_edit = control.find_child("GraphEdit")
	graph_edit.connection_request.connect(_on_request)
	recipe_node = load("res://addons/recipe_tree/recipe_node.tscn")
	gadget_node = load("res://addons/recipe_tree/gadget_node.tscn")
	item_node = load("res://addons/recipe_tree/item_node.tscn")
	load_recipes()
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(load_recipes)
	
func _on_request(from, from_port, to, to_port):
	graph_edit.connect_node(str(from), from_port, str(to), to_port)

func _process(_delta:float) -> void:
	populate_nodes("recipe_node", properties.recipe_nodes, recipe_node)
	populate_nodes("gadget_node", properties.gadget_nodes, gadget_node)
	populate_nodes("item_node", properties.item_nodes, item_node)
	var graph_nodes:Array = graph_edit.get_children().filter(func(child): return child is GraphNode)
	for node in graph_nodes:
		if "recipe_node" in node:
			var connections:Array = graph_edit.get_connection_list().filter(func(connection): return connection.from_node == node.get_name())
			var found_inputs:Array
			var found_outputs:Array
			var found_gadgets:Array
			if node.get_input_port_count() >= node.recipe_node.recipe.inputs.size() + node.recipe_node.output_item_nodes.size() + 1:
			# If this isn't true, then the nodes have yet to be initialized, so no point in doing anything involving them
				for connection in connections:
					var from_node:Node = graph_edit.find_child(connection.from_node)
					if "item_node" not in from_node or from_node.item_node == null:
						if "gadget_node" not in from_node or from_node.gadget_node == null: continue
						if from_node.gadget_node != node.recipe_node.gadget_node:
							graph_edit.disconnect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)
						else:
							found_gadgets.append(from_node.gadget_node)
					else:
						if from_node.item_node not in node.recipe_node.input_nodes and from_node.item_node not in node.recipe_node.output_nodes:
							graph_edit.disconnect_node(connection.from_node, connection.from_port, connection.from_node, connection.from_port)
						elif from_node.item_node in node.recipe_node.input_item_nodes:
							found_inputs.append(from_node.item_node)
						elif from_node.item_node in node.recipe_node.output_item_nodes:
							found_outputs.append(from_node.item_node)
				
				for index in range(node.recipe_node.input_item_nodes.size()):
					# Connect all nodes that are connected in the resource
					var input = node.recipe_node.input_item_nodes[index]
					var connectable:Array = graph_edit.get_children().filter(func(child_node): return "item_node" in child_node and child_node.item_node == input)
					if connectable.is_empty(): continue
					var to_connect = connectable[0]
					if input not in found_inputs:
						graph_edit.connect_node(to_connect.get_name(), 0, node.get_name(), index)
	
				var gadget = node.recipe_node.gadget_node
				var gadget_connectable:Array = graph_edit.get_children().filter(func(child_node): return "gadget_node" in child_node and child_node.gadget_node == gadget)
				if !gadget_connectable.is_empty():
					var to_connect = gadget_connectable[0]
					if gadget not in found_gadgets:
						graph_edit.connect_node(to_connect.get_name(), 0, node.get_name(), node.recipe_node.recipe.inputs.size())
				
				for index in range(node.recipe_node.output_item_nodes.size()):
					var output = node.recipe_node.output_item_nodes[index]
					var connectable:Array = graph_edit.get_children().filter(func(child_node): return "item_node" in child_node and child_node.item_node == output)
					if connectable.is_empty(): continue
					var to_connect = connectable[0]
					if output not in found_outputs:
						# Cumulative, so plus input nodes size. Plus 1 to account for gadget
						graph_edit.connect_node(to_connect.get_name(), 0, node.get_name(), index + node.recipe_node.recipe.inputs.size() + 1)

		

## Arbitrarily populate nodes with a given variable name for subnode (recipe_node, graph_node, item_node)
## and a list of the property nodes that correspond, and finally with the scene that will be made
func populate_nodes(node_var_name:String, property_nodes:Array, new_node_type:PackedScene):
	var nodes:Array = graph_edit.get_children().filter(func(child): return node_var_name in child)
	var remove_nodes:Array
	for node:GraphNode in nodes:
	# If there is a recipe node that shouldn't be in there, remove it
		if node.get(node_var_name) not in property_nodes:
			remove_nodes.append(node) # So that the for loop doesn't get disrupted by removal
	
	for node in remove_nodes:
		node.moved.disconnect(node_moved)
		graph_edit.remove_child(node)
	
	for node in property_nodes:
	# Consequently, if there is a node missing, add it
		if graph_edit.get_children().filter(func(child): return node_var_name in child and child.get(node_var_name) == node).is_empty():
	# If the graph_edit doesn't contain a node which is the node we're looking at inside of it
			var new_node:GraphNode = new_node_type.instantiate()
			new_node.position_offset = Vector2(node.x, node.y)
			new_node.set(node_var_name, node)
			new_node.moved.connect(node_moved)
			graph_edit.add_child(new_node)

func node_moved(to:Vector2, node) -> void:
	var changed_node
	if node is RecipeEditorNode:
		changed_node = properties.recipe_nodes[properties.recipe_nodes.find(node)]
	elif node is GadgetEditorNode:
		changed_node = properties.gadget_nodes[properties.gadget_nodes.find(node)]
	elif node is ItemEditorNode:
		changed_node = properties.item_nodes[properties.item_nodes.find(node)]
	changed_node.x = to.x
	changed_node.y = to.y
	save_properties()

func load_recipes() -> void:
	recipe_strings.clear()
	recipes.clear()
	load_path("res://resources/recipes", TYPE.RECIPE)
	load_gadgets()
	load_items()
	if !recipe_strings.is_empty():
		for recipe_string in recipe_strings:
			recipes.append(load(recipe_string))
	for recipe in recipes:
		if properties.recipe_nodes.filter(func(recipe_node): return recipe_node.recipe == recipe).is_empty():
			# If there does not exist a recipe node for the given recipe
			var new_recipe:RecipeEditorNode = RecipeEditorNode.new()
			new_recipe.x = 100
			new_recipe.y = 100
			new_recipe.recipe = recipe
			new_recipe.gadget_node = null
			properties.recipe_nodes.append(new_recipe)
			save_properties()
	for index in range(properties.recipe_nodes.size()):
		# validate if recipe exists
		var recipe_node:RecipeEditorNode = properties.recipe_nodes[index]
		if recipe_node.recipe not in recipes:
			properties.recipe_nodes.remove_at(index)
			save_properties()
			continue
		var recipe:Recipe = recipe_node.recipe
		if recipe.gadget in gadgets:
			if properties.gadget_nodes.filter(func(gadget_node): return gadget_node.gadget == recipe.gadget).is_empty():
				# if the gadget corresponding to this recipe does not exist
				var new_gadget:GadgetEditorNode = GadgetEditorNode.new()
				new_gadget.x = 0
				new_gadget.y = 0
				new_gadget.gadget = recipe.gadget
				properties.gadget_nodes.append(new_gadget)
				recipe_node.gadget_node = new_gadget
				save_properties()
		if !recipe.inputs.is_empty():
			for slot:Slot in recipe.inputs:
				if slot != null:
					var item:Item = slot.item
					if item in items:
						if properties.item_nodes.filter(func(item_node): return item_node.item == item).is_empty():
							var new_item:ItemEditorNode = ItemEditorNode.new()
							new_item.x = 0
							new_item.y = 0
							new_item.item = item
							properties.item_nodes.append(new_item)
							recipe_node.input_item_nodes.append(new_item)
							save_properties()
		if !recipe.outputs.is_empty():
			for slot:Slot in recipe.outputs:
				var item:Item = slot.item
				if item in items:
					if properties.item_nodes.filter(func(item_node): return item_node.item == item).is_empty():
						var new_item:ItemEditorNode = ItemEditorNode.new()
						new_item.x = 0
						new_item.y = 0
						new_item.item = item
						properties.item_nodes.append(new_item)
						recipe_node.output_item_nodes.append(new_item)
						save_properties()

func load_gadgets() -> void:
	gadget_strings.clear()
	gadgets.clear()
	load_path("res://resources/gadgets", TYPE.GADGET)
	validate_gadgets()
	
func validate_gadgets() -> void:
	if !gadget_strings.is_empty():
		for gadget_string in gadget_strings:
			gadgets.append(load(gadget_string))
	var remove_gadgets:Array = []
	for index in range(properties.gadget_nodes.size()):
		var gadget_node:GadgetEditorNode = properties.gadget_nodes[index]
		if gadget_node.gadget not in gadgets:
			# if the gadget isn't a resoruce, or if it isn't valid (the recipe no longer exists)
			gadget_node.clear()
			remove_gadgets.append(index)
	for index in range(remove_gadgets.size()):
		properties.gadget_nodes.remove_at(remove_gadgets[index] - index) # by minusing by the index, we account for the index shifting down every removal
	if !remove_gadgets.is_empty():
		save_properties() # only save if items were removed, to avoid infinite loops
		
func load_items() -> void:
	item_strings.clear()
	items.clear()
	load_path("res://resources/items", TYPE.ITEM)
	validate_items()
	
func validate_items() -> void:
	if !item_strings.is_empty():
		for item_string in item_strings:
			items.append(load(item_string))
	var remove_items:Array = []
	for index in range(properties.item_nodes.size()):
		var item_node:ItemEditorNode = properties.item_nodes[index]
		if item_node.item not in items:
			# if the item isn't a resource, or if it isn't valid (the recipe no longer exists)
			item_node.clear()
			remove_items.append(index) # can't remove while iterating through list
	for index in range(remove_items.size()):
		properties.item_nodes.remove_at(remove_items[index] - index) # by minusing by the index, we account for the index shifting down every removal
	if !remove_items.is_empty():
		save_properties() # only save if items were removed, to avoid infinite loops
		
func load_path(path:String, type:int) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				load_path(dir.get_current_dir(), type)
			else:
				var full_path:String = path + "/" + file_name
				if type == TYPE.RECIPE:
					recipe_strings.append(full_path)
				elif type == TYPE.GADGET:
					gadget_strings.append(full_path)
				elif type == TYPE.ITEM:
					item_strings.append(full_path)
			# found recipe
			file_name = dir.get_next()
	else:
		assert(dir != null, "Directory not found! Should be at 'res://resources/" +
		("recipes" if type == TYPE.RECIPE else "gadgets" if type == TYPE.GADGET else "items") + "'")

func save_properties() -> void:
	ResourceSaver.save(properties, properties.get_path())
	properties.take_over_path(properties.get_path())


func _exit_tree() -> void:
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_SIDE_RIGHT, control)
	control.free()
