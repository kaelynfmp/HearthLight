@tool
extends EditorPlugin

var control
var recipe_strings:PackedStringArray
var recipes:Array[Recipe]
var gadget_strings:PackedStringArray
var gadgets:Array[Gadget]
var item_strings:PackedStringArray
var items:Array[Item]
var valid_gadget_nodes:Array[GadgetEditorNode]
var valid_item_nodes:Array[ItemEditorNode]
var properties:RecipeTreeProperties = preload("res://addons/recipe_tree/recipe_tree_properties.tres")
enum TYPE {
	RECIPE, GADGET, ITEM
}

func _enter_tree() -> void:
	control = preload("res://addons/recipe_tree/recipe_tree.tscn").instantiate()
	add_control_to_container(CONTAINER_CANVAS_EDITOR_SIDE_RIGHT, control)
	load_recipes()
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(load_recipes)
	
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
	valid_gadget_nodes.clear()
	valid_item_nodes.clear()
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
		# create list of valid gadgets and items
		valid_gadget_nodes.append(recipe_node.gadget_node)
		for item_node:ItemEditorNode in recipe_node.input_item_nodes:
			valid_item_nodes.append(item_node)
		for item_node:ItemEditorNode in recipe_node.output_item_nodes:
			valid_item_nodes.append(item_node)
	# re-validate now that valid lists have been made
	validate_gadgets()
	validate_items()

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
		if gadget_node.gadget not in gadgets or gadget_node not in valid_gadget_nodes:
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
		if item_node.item not in items or item_node not in valid_item_nodes:
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
