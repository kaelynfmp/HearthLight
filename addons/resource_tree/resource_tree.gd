﻿@tool
extends EditorPlugin

var control
var recipe_strings:PackedStringArray
var recipes:Array[Recipe]
var gadget_strings:PackedStringArray
var gadgets:Array[Gadget]
var item_strings:PackedStringArray
var items:Array[Item]
var prev_gadgets:Array[Gadget]
var prev_items:Array[Item]
var email_strings:PackedStringArray
var emails:Array[Email]

var gadget_menu:PopupMenu
var item_menu:PopupMenu

var properties:RecipeTreeProperties = preload("res://addons/resource_tree/resource_tree_properties.tres")

var graph_edit:GraphEdit
var menu_node:MenuBar

var recipe_node:PackedScene
var gadget_node:PackedScene
var item_node:PackedScene
var email_node:PackedScene
var menu:PackedScene
var recipe_popup_scene:PackedScene
var item_popup_scene:PackedScene
var gadget_popup_scene:PackedScene
var email_popup_scene:PackedScene

var recipe_popup:PopupPanel
var item_popup:PopupPanel
var gadget_popup:PopupPanel
var email_popup:PopupPanel

func _ready() -> void:
	recipe_node = load("res://addons/resource_tree/recipe_node.tscn")
	gadget_node = load("res://addons/resource_tree/gadget_node.tscn")
	item_node = load("res://addons/resource_tree/item_node.tscn")
	email_node = load("res://addons/resource_tree/email_node.tscn")
	menu = load("res://addons/resource_tree/recipe_menu.tscn")
	recipe_popup_scene = load("res://addons/resource_tree/recipe_popup.tscn")
	item_popup_scene = load("res://addons/resource_tree/item_popup.tscn")
	gadget_popup_scene = load("res://addons/resource_tree/gadget_popup.tscn")
	email_popup_scene = load("res://addons/resource_tree/email_popup.tscn")
	
	control = preload("res://addons/resource_tree/resource_tree.tscn").instantiate()
	EditorInterface.get_editor_main_screen().add_child(control)
	control.hide()
	
	graph_edit = control
	graph_edit.connection_request.connect(_on_request)
	graph_edit.disconnection_request.connect(_on_disconnect_request)
	graph_edit.add_valid_connection_type(0, 3)
	graph_edit.add_valid_connection_type(1, 3)
	
	menu_node = menu.instantiate()
	graph_edit.get_menu_hbox().add_child(menu_node)
	menu_node.find_child("AddRecipe").pressed.connect(_add_recipe)
	menu_node.find_child("AddEmail").pressed.connect(_add_email)

	item_menu = menu_node.find_child("Add Resource")
	gadget_menu = menu_node.find_child("Add Gadget")

	populate_menu_gadgets()
	populate_menu_items()

	item_menu.index_pressed.connect(item_menu_pressed)
	gadget_menu.index_pressed.connect(gadget_menu_pressed)
	load_recipes()
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(load_recipes)
	
func _has_main_screen() -> bool:
	return true
	
func _make_visible(visible):
	control.visible = visible

func _get_plugin_name() -> String:
	return "Resource Tree"

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("GraphEdit", "EditorIcons")

func _add_recipe():
	recipe_popup = recipe_popup_scene.instantiate()
	control.add_child(recipe_popup)
	recipe_popup.show()
	recipe_popup.find_child("Confirm", true).pressed.connect(add_named_recipe)

func add_named_recipe():
	var recipe_name:String = "generated"
	recipe_name = recipe_popup.find_child("Name").get_text()
	var new_recipe:Recipe = Recipe.new()
	new_recipe.set_name(recipe_name + "_recipe")
	var path:String = "res://resources/recipes/" + new_recipe.get_name() + ".tres"
	ResourceSaver.save(new_recipe, path)
	new_recipe.take_over_path(path)
	recipe_popup.hide()
	
func _add_email():
	email_popup = email_popup_scene.instantiate()
	control.add_child(email_popup)
	email_popup.show()
	email_popup.find_child("Confirm", true).pressed.connect(add_named_email)
	
func add_named_email():
	var email_name:String = "generated"
	email_name = email_popup.find_child("Name").get_text()
	var new_email:Email = Email.new()
	new_email.set_name(email_name)
	var path:String = "res://resources/emails/" + new_email.get_name() + ".tres"
	ResourceSaver.save(new_email, path)
	new_email.take_over_path(path)
	email_popup.hide()

func _on_request(from, from_port, to, to_port) -> void:
	# If that node already has a connection, we should not be able to connect to it
	var node:GraphNode = graph_edit.get_children().filter(func(child): return child.name == to)[0]
	var valid: bool = true
	var connections: Array = graph_edit.get_connection_list().filter(func(connection): return connection.to_node == to and connection.to_port == to_port)
	var to_connect_node:GraphNode = graph_edit.get_children().filter(func(child): return child.name == from)[0]
	valid = connections.is_empty() or "email_node" in node
	if valid:
		connect_nodes(from, from_port, to, to_port, node, to_connect_node)
	elif "email_node" not in node:
		var to_disconnect_node:GraphNode = graph_edit.get_children().filter(func(child): return child.name == from)[0]
		
		var gadget_node:bool
		var stored_recipe_inputs:Array[Slot]
		var stored_recipe_outputs:Array[Slot]
		var stored_recipe_input_nodes:Array[ItemEditorNode]
		var stored_recipe_output_nodes:Array[ItemEditorNode]
		if to_port == node.recipe_node.recipe.inputs.size():
			gadget_node = true
			stored_recipe_inputs = node.recipe_node.recipe.inputs.duplicate()
			stored_recipe_outputs = node.recipe_node.recipe.outputs.duplicate()
			stored_recipe_input_nodes = node.recipe_node.input_item_nodes.duplicate()
			stored_recipe_output_nodes = node.recipe_node.output_item_nodes.duplicate()
		# to port will changed after disconnect so this needs to be manual
		disconnect_nodes(from, from_port, to, to_port, node, to_disconnect_node)
		# Hotswap
		if !gadget_node:
			if to_port < node.recipe_node.recipe.inputs.size():
				# Input
				var find_node = node.recipe_node.input_item_nodes.find(to_disconnect_node.item_node)
				if find_node != 1:
					graph_edit.disconnect_node(node.recipe_node.input_item_nodes[find_node].get_name(), from_port, to, to_port)
					node.recipe_node.clear_input_item_node(node.recipe_node.input_item_nodes[find_node])
					save_properties()
			else:
				# Output
				var find_node = node.recipe_node.output_item_nodes.find(to_disconnect_node.item_node)
				if find_node != 1:
					graph_edit.disconnect_node(node.recipe_node.output_item_nodes[find_node].get_name(), from_port, to, to_port)
					node.recipe_node.clear_output_item_node(node.recipe_node.output_item_nodes[find_node])
					save_properties()
			connect_nodes(from, from_port, to, to_port, node, to_connect_node)
		else:
			# Gadget
			var find_node = node.recipe_node.gadget_node
			if find_node != null:
				graph_edit.disconnect_node(node.recipe_node.gadget_node.get_name(), from_port, to, node.recipe_node.recipe.inputs.size())
				node.recipe_node.clear_gadget_node()
			save_properties()
			connect_nodes(from, from_port, to, to_connect_node.gadget_node.gadget.inputs, node, to_connect_node, true)
			# Fixes bug where for whatever reason gadget hotswap doesn't update inputs
			node.queue_free()
			node.recipe_node.recipe.inputs = stored_recipe_inputs
			node.recipe_node.recipe.outputs = stored_recipe_outputs
			node.recipe_node.input_item_nodes = stored_recipe_input_nodes
			node.recipe_node.output_item_nodes = stored_recipe_output_nodes
			save_properties()
		
		
		
func connect_nodes(from, from_port, to, to_port, node, to_connect_node, gadget_node=false) -> void:
	if "recipe_node" in node:
		if to_port < node.recipe_node.recipe.inputs.size() and not gadget_node:
			# Input
			if node.recipe_node.input_item_nodes.find(to_connect_node.item_node) != -1: return
			node.recipe_node.input_item_nodes.append(to_connect_node.item_node)
		elif to_port == node.recipe_node.recipe.inputs.size() or gadget_node:
			# Gadget
			node.recipe_node.gadget_node = to_connect_node.gadget_node
		elif not gadget_node:
			# Output
			if node.recipe_node.output_item_nodes.find(to_connect_node.item_node) != -1: return
			node.recipe_node.output_item_nodes.append(to_connect_node.item_node)
		graph_edit.connect_node(str(from), from_port, str(to), to_port)
	elif "email_node" in node:
		var email:Email = node.email_node.email
		if "email_node" in to_connect_node:
			# Appending directly was causing a resource cache issue occasionally, so this guarantees it works
			var new_emails:Array[Email] = email.prerequisite_emails.duplicate()
			new_emails.append(to_connect_node.email_node.email)
			email.prerequisite_emails = new_emails
		elif "item_node" in to_connect_node or "gadget_node" in to_connect_node:
			var existing_connection:bool = graph_edit.get_connection_list().any(func(connection): \
			return connection.from_node == from and connection.from_port == from_port and connection.to_node == to and connection.to_port == to_port)
			if existing_connection: return
			var is_item:bool = "item_node" in to_connect_node
			var order:Order = email.attached_order
			if !order: return
			match to_port:
				1:
					var new_given_items:Array[Resource] = order.given_items.duplicate()
					new_given_items.append(to_connect_node.item_node.item if is_item else to_connect_node.gadget_node.gadget)
					var new_given_quantities:Array[int] = order.given_quantities.duplicate()
					new_given_quantities.append(1)
					order.given_items = new_given_items
					order.given_quantities = new_given_quantities
					node.email_node.given_item_nodes[to_connect_node.item_node if is_item else to_connect_node.gadget_node] = 1
				2:
					var new_required_items:Array[Resource] = order.required_items.duplicate()
					new_required_items.append(to_connect_node.item_node.item if is_item else to_connect_node.gadget_node.gadget)
					var new_required_quantities:Array[int] = order.required_quantities.duplicate()
					new_required_quantities.append(1)
					order.required_items = new_required_items
					order.required_quantities = new_required_quantities
					node.email_node.required_item_nodes[to_connect_node.item_node if is_item else to_connect_node.gadget_node] = 1
				3:
					var new_rewards_items:Array[Resource] = order.rewards.duplicate()
					new_rewards_items.append(to_connect_node.item_node.item if is_item else to_connect_node.gadget_node.gadget)
					var new_rewards_quantities:Array[int] = order.rewards_quantities.duplicate()
					new_rewards_quantities.append(1)
					order.rewards = new_rewards_items
					order.rewards_quantities = new_rewards_quantities
					node.email_node.rewards_item_nodes[to_connect_node.item_node if is_item else to_connect_node.gadget_node] = 1
				4:
					var new_unlocks_items:Array[Resource] = order.unlocks.duplicate()
					new_unlocks_items.append(to_connect_node.item_node.item if is_item else to_connect_node.gadget_node.gadget)
					order.unlocks = new_unlocks_items
					node.email_node.unlocks_item_nodes[to_connect_node.item_node if is_item else to_connect_node.gadget_node] = 1
			
	save_properties()
	
func disconnect_nodes(from, from_port, to, to_port, node, to_disconnect_node):
	if "recipe_node" in node:
		if to_port < node.recipe_node.recipe.inputs.size():
			# Input
			var find_node = node.recipe_node.input_item_nodes.find(to_disconnect_node.item_node)
			if find_node != -1:
				node.recipe_node.clear_input_item_node(node.recipe_node.input_item_nodes[find_node])
		elif to_port == node.recipe_node.recipe.inputs.size():
			# Gadget
			var stored_recipe_inputs:Array[Slot]
			var stored_recipe_outputs:Array[Slot]
			var stored_recipe_input_nodes:Array[ItemEditorNode]
			var stored_recipe_output_nodes:Array[ItemEditorNode]
			if to_port == node.recipe_node.recipe.inputs.size():
				stored_recipe_inputs = node.recipe_node.recipe.inputs.duplicate()
				stored_recipe_outputs = node.recipe_node.recipe.outputs.duplicate()
				stored_recipe_input_nodes = node.recipe_node.input_item_nodes.duplicate()
				stored_recipe_output_nodes = node.recipe_node.output_item_nodes.duplicate()
			var find_node = node.recipe_node.gadget_node
			if find_node != null:
				node.recipe_node.clear_gadget_node()
				node.recipe_node.recipe.inputs = stored_recipe_inputs
				node.recipe_node.recipe.outputs = stored_recipe_outputs
				node.recipe_node.input_item_nodes = stored_recipe_input_nodes
				node.recipe_node.output_item_nodes = stored_recipe_output_nodes
		else:
			# Output
			var find_node = node.recipe_node.output_item_nodes.find(to_disconnect_node.item_node)
			if find_node != -1:
				node.recipe_node.clear_output_item_node(node.recipe_node.output_item_nodes[find_node])
		graph_edit.disconnect_node(from, from_port, to, to_port)
	elif "email_node" in node:
		if "email_node" in to_disconnect_node:
			node.email_node.email.prerequisite_emails.erase(to_disconnect_node.email_node.email)
		elif "item_node" in to_disconnect_node or "gadget_node" in to_disconnect_node:
			var is_item:bool = "item_node" in to_disconnect_node
			var order:Order = node.email_node.email.attached_order
			if !order: return
			match to_port:
				1:
					var new_given_items:Array[Resource] = order.given_items.duplicate()
					var new_given_quantities:Array[int] = order.given_quantities.duplicate()
					new_given_quantities.remove_at(new_given_items.find(to_disconnect_node.item_node.item if is_item else to_disconnect_node.gadget_node.gadget))
					new_given_items.erase(to_disconnect_node.item_node.item if is_item else to_disconnect_node.gadget_node.gadget)
					order.given_items = new_given_items
					order.given_quantities = new_given_quantities
					node.email_node.given_item_nodes.erase(to_disconnect_node.item_node if is_item else to_disconnect_node.gadget_node)
				2:
					var new_required_items:Array[Resource] = order.required_items.duplicate()
					var new_required_quantities:Array[int] = order.required_quantities.duplicate()
					new_required_quantities.remove_at(new_required_items.find(to_disconnect_node.item_node.item if is_item else to_disconnect_node.gadget_node.gadget))
					new_required_items.erase(to_disconnect_node.item_node.item if is_item else to_disconnect_node.gadget_node.gadget)
					order.required_items = new_required_items
					order.required_quantities = new_required_quantities
					node.email_node.required_item_nodes.erase(to_disconnect_node.item_node if is_item else to_disconnect_node.gadget_node)
				3:
					var new_rewards_items:Array[Resource] = order.rewards.duplicate()
					var new_rewards_quantities:Array[int] = order.rewards_quantities.duplicate()
					new_rewards_quantities.remove_at(new_rewards_items.find(to_disconnect_node.item_node.item if is_item else to_disconnect_node.gadget_node.gadget))
					new_rewards_items.erase(to_disconnect_node.item_node.item if is_item else to_disconnect_node.gadget_node.gadget)
					order.rewards = new_rewards_items
					order.rewards_quantities = new_rewards_quantities
					node.email_node.rewards_item_nodes.erase(to_disconnect_node.item_node if is_item else to_disconnect_node.gadget_node)
				4:
					var new_unlocks_items:Array[Resource] = order.unlocks.duplicate()
					new_unlocks_items.erase(to_disconnect_node.item_node.item if is_item else to_disconnect_node.gadget_node.gadget)
					order.unlocks = new_unlocks_items
					node.email_node.unlocks_item_nodes.erase(to_disconnect_node.item_node if is_item else to_disconnect_node.gadget_node)
	save_properties()
	
func _on_disconnect_request(from, from_port, to, to_port) -> void:
	var node:GraphNode = graph_edit.get_children().filter(func(child): return child.name == to)[0] # Unique nameness means this is the node we want
	var to_disconnect_node:GraphNode = graph_edit.get_children().filter(func(child): return child.name == from)[0]
	disconnect_nodes(from, from_port, to, to_port, node, to_disconnect_node)
	

func _process(_delta:float) -> void:
	if (!control.visible): return
	populate_nodes("recipe_node", properties.recipe_nodes, recipe_node)
	populate_nodes("gadget_node", properties.gadget_nodes, gadget_node)
	populate_nodes("item_node", properties.item_nodes, item_node)
	populate_nodes("email_node", properties.email_nodes, email_node)
	if (prev_items != items):
		prev_items = items.duplicate()
		populate_menu_items()
	if (prev_gadgets != gadgets):
		prev_gadgets = gadgets.duplicate()
		populate_menu_gadgets()
	var graph_nodes:Array[Node] = graph_edit.get_children().filter(func(child): return child is GraphNode and "recipe_node" in child)
	for node in graph_nodes:
		var connections:Array = graph_edit.get_connection_list().filter(func(connection): return connection.to_node == node.get_name())
		var found_inputs:Array
		var found_outputs:Array
		var found_gadgets:Array
		if node.get_input_port_count() == node.recipe_node.recipe.inputs.size() + node.recipe_node.recipe.outputs.size() + 1:
		# If this isn't true, then the nodes have yet to be initialized, so no point in doing anything involving them
			var remove_inputs:Array[int]
		
			for index in range(node.recipe_node.input_item_nodes.size()):
				var input:ItemEditorNode = node.recipe_node.input_item_nodes[index]
				# Validate that the item exists
				if input not in properties.item_nodes:
					remove_inputs.append(index)
					continue

				# If the input does not actually belong to the recipe, remove it
				# manual find because find isnt working on typed array
				var found_index:int = -1
				for jndex in range(node.recipe_node.recipe.inputs.size()):
					var item = node.recipe_node.recipe.inputs[jndex].item
					if item == input.item:
						found_index = jndex
						break

				if found_index == -1:
					remove_inputs.append(index)
					continue

				# Connect all nodes that are connected in the resource
				var connectable:Array = graph_edit.get_children().filter(func(child_node): return "item_node" in child_node and child_node.item_node == input)
				if connectable.is_empty(): continue
				var to_connect = connectable[0]
				if input not in found_inputs:
					graph_edit.connect_node(to_connect.get_name(), 0, node.get_name(), index)

			for index in range(remove_inputs.size()):
				node.recipe_node.input_item_nodes.remove_at(remove_inputs[index] - index)

			var gadget = node.recipe_node.gadget_node
			if gadget not in properties.gadget_nodes:
				node.recipe_node.gadget_node = null
			else:
				var gadget_connectable:Array = graph_edit.get_children().filter(func(child_node): return "gadget_node" in child_node and child_node.gadget_node == gadget)
				if !gadget_connectable.is_empty():
					var to_connect = gadget_connectable[0]
					if gadget not in found_gadgets:
						graph_edit.connect_node(to_connect.get_name(), 0, node.get_name(), node.recipe_node.recipe.inputs.size())
			
			var remove_outputs:Array[int]

			for index in range(node.recipe_node.output_item_nodes.size()):
				var output = node.recipe_node.output_item_nodes[index]
				# Validate that the item exists		
				if output not in properties.item_nodes:
					remove_inputs.append(index)
					continue

				# If the input does not actually belong to the recipe, remove it
				# manual find because find isnt working on typed array
				var found_index:int = -1
				for jndex in range(node.recipe_node.recipe.outputs.size()):
					var item = node.recipe_node.recipe.outputs[jndex].item
					if item == output.item:
						found_index = jndex
						break
				
				if found_index == -1:
					remove_outputs.append(index)
					continue

				# Connect all nodes that are connected in the resource
				var connectable:Array = graph_edit.get_children().filter(func(child_node): return "item_node" in child_node and child_node.item_node == output)
				if connectable.is_empty(): continue
				var to_connect = connectable[0]
				if output not in found_outputs:
					# Cumulative, so plus input nodes size. Plus 1 to account for gadget
					graph_edit.connect_node(to_connect.get_name(), 0, node.get_name(), index + node.recipe_node.recipe.inputs.size() + 1)
			
			for index in range(remove_outputs.size()):
				node.recipe_node.output_item_nodes.remove_at(remove_outputs[index] - index)

			for connection in connections:
				var from_node:Node = graph_edit.get_children().filter(func(child): return child.name == connection.from_node)[0]
				if "item_node" not in from_node or from_node.item_node == null:
					if "gadget_node" not in from_node or from_node.gadget_node == null: continue
					if from_node.gadget_node != node.recipe_node.gadget_node:
						graph_edit.disconnect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)
					else:
						found_gadgets.append(from_node.gadget_node)
				else:
					if from_node.item_node == null:
						graph_edit.disconnect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)
					if connection.to_port < node.recipe_node.recipe.inputs.size():
						# Input
						if from_node.item_node not in node.recipe_node.input_item_nodes:
							graph_edit.disconnect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)
					elif connection.to_port == node.recipe_node.recipe.inputs.size():
						# Gadget
						if from_node.gadget_node != node.recipe_node.gadget_node:
							graph_edit.disconnect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)
					else:
						# Output
						if from_node.item_node not in node.recipe_node.output_item_nodes:
							graph_edit.disconnect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)

	graph_nodes = graph_edit.get_children().filter(func(child): return child is GraphNode and "email_node" in child)
	for node in graph_nodes:
		var connections:Array = graph_edit.get_connection_list().filter(func(connection): return connection.to_node == node.get_name())
		#if node.get_input_port_count() == node.email_node.email.prerequisite_emails.size() + ((node.email_node.email.attached_order.required_items.size() + node.email_node.email.attached_order.given_items.size()) if node.email_node.email.attached_order != null else 0) + 1:
		var email_node:EmailEditorNode = node.email_node
		var email:Email = email_node.email

		# Prerequisite Email Setup
		if email_node.prerequisite_email_nodes.size() != email.prerequisite_emails.size() \
		or !email_node.prerequisite_email_nodes.all(\
		func(prerequisite_email_node): return prerequisite_email_node.email in email.prerequisite_emails):
			# If size or contents is different
			email_node.prerequisite_email_nodes.clear()
			for prerequisite_email in email.prerequisite_emails:
				var find_node = graph_nodes.filter(func(graph_node): return graph_node.email_node.email == prerequisite_email)
				if !find_node.is_empty():
					var prerequisite_email_node = find_node[0]
					email_node.prerequisite_email_nodes.append(prerequisite_email_node.email_node)

		# Check if the connection exists. If not, make it
		for prerequisite_email_node:EmailEditorNode in email_node.prerequisite_email_nodes:
			var prereq_graph_node = graph_nodes.filter(func(graph_node): return graph_node.email_node == prerequisite_email_node)
			if !prereq_graph_node.is_empty():
				var existing_connections:Array = connections.filter(func(connection): return connection.from_node == prereq_graph_node[0].get_name())
				if existing_connections.is_empty():
					graph_edit.connect_node(prereq_graph_node[0].get_name(), 0, node.get_name(), 0)

		## ORDERS
		var order:Order = email.attached_order
		if order != null:
			var item_nodes:Array[Node] = graph_edit.get_children().filter(func(child): return child is GraphNode and "item_node" in child)
			var gadget_nodes:Array[Node] = graph_edit.get_children().filter(func(child): return child is GraphNode and "gadget_node" in child)
			var set_items := func (set_item_nodes, items_list, quantities_list):
				var contents_same:bool = set_item_nodes.keys().all(\
					func(item_node): return (item_node.gadget if item_node is GadgetEditorNode else item_node.item) in items_list and \
					set_item_nodes[item_node] == quantities_list[set_item_nodes.keys().find(item_node)])
				var node_exists:bool = set_item_nodes.keys().all(func(item_node): return item_nodes.any(func(check_node): return check_node.item_node == item_node)\
					if item_node is ItemEditorNode else gadget_nodes.any(func(check_node): return check_node.gadget_node == item_node))
				
				if set_item_nodes.size() != items_list.size() or !contents_same or !node_exists:
					# If size or contents is different, or if the node no longer exists in the graph view
					set_item_nodes.clear()
					for index in range(items_list.size()):
						var new_item:Resource = items_list[index]
						if new_item == null: return
						var new_quantity:int = quantities_list[index]
						var find_node:Array[Node] = item_nodes.filter(func(graph_node): return graph_node.item_node.item == new_item)
						if find_node.is_empty():
							find_node = gadget_nodes.filter(func(graph_node): return graph_node.gadget_node.gadget == new_item)
						if !find_node.is_empty():
							set_item_nodes[(find_node[0].item_node if new_item is Item else find_node[0].gadget_node)] = new_quantity
						else:
							set_item_nodes[add_item(new_item)] = new_quantity

			set_items.call(email_node.given_item_nodes, order.given_items, order.given_quantities)
			set_items.call(email_node.required_item_nodes, order.required_items, order.required_quantities)
			set_items.call(email_node.rewards_item_nodes, order.rewards, order.rewards_quantities)
			var unlocks_array:Array[int] = []
			unlocks_array.resize(order.unlocks.size())
			unlocks_array.fill(1)
			set_items.call(email_node.unlocks_item_nodes, order.unlocks, unlocks_array)

			var connect_nodes := func(to_connect_nodes:Dictionary[Resource, int], port:int):
				for to_connect_node in to_connect_nodes.keys():
					var graph_node:Array[Node] = item_nodes.filter(func(check_graph_node): return check_graph_node.item_node == to_connect_node)
					if graph_node.is_empty():
						graph_node = gadget_nodes.filter(func(check_graph_node): return check_graph_node.gadget_node == to_connect_node)
					if !graph_node.is_empty():
						var existing_connections:Array = connections.filter(func(connection): return connection.from_node == graph_node[0].get_name() and connection.to_port == port)
						if existing_connections.is_empty():
							graph_edit.connect_node(graph_node[0].get_name(), 0, node.get_name(), port)

			connect_nodes.call(email_node.given_item_nodes, 1)
			connect_nodes.call(email_node.required_item_nodes, 2)
			connect_nodes.call(email_node.rewards_item_nodes, 3)
			connect_nodes.call(email_node.unlocks_item_nodes, 4)

			
		
		for connection in connections:
			# Check if the connection exists. If it is, but shouldn't, un-make it
			var from_node:Node = graph_edit.get_children().filter(func(child): return child.name == connection.from_node)[0]
			if "email_node" in from_node:
				if from_node.email_node not in email_node.prerequisite_email_nodes:
					graph_edit.disconnect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)
			elif "item_node" in from_node or "gadget_node" in from_node:
				var is_item:bool = "item_node" in from_node
				var from_item_node = from_node.item_node if is_item else from_node.gadget_node
				if order != null:
					match connection.to_port:
						1:
							if from_item_node not in email_node.given_item_nodes:
								graph_edit.disconnect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)
						2:
							if from_item_node not in email_node.required_item_nodes:
								graph_edit.disconnect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)
						3:
							if from_item_node not in email_node.rewards_item_nodes:
								graph_edit.disconnect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)
						4:
							if from_item_node not in email_node.unlocks_item_nodes:
								graph_edit.disconnect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)



## Arbitrarily populate nodes with a given variable name for subnode (recipe_node, graph_node, item_node)
## and a list of the property nodes that correspond, and finally with the scene that will be made
func populate_nodes(node_var_name:String, property_nodes:Array, new_node_type:PackedScene):
	var nodes:Array = graph_edit.get_children().filter(func(child): return node_var_name in child)
	var remove_nodes:Array
	for node:GraphNode in nodes:
	# If there is a node that shouldn't be in there, remove it
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
			new_node.kill.connect(remove_node)
			graph_edit.add_child(new_node)
			new_node.name = node_var_name + new_node.name

func node_moved(to:Vector2, node) -> void:
	var changed_node
	if node is RecipeEditorNode:
		changed_node = properties.recipe_nodes[properties.recipe_nodes.find(node)]
	elif node is GadgetEditorNode:
		changed_node = properties.gadget_nodes[properties.gadget_nodes.find(node)]
	elif node is ItemEditorNode:
		changed_node = properties.item_nodes[properties.item_nodes.find(node)]
	elif node is EmailEditorNode:
		changed_node = properties.email_nodes[properties.email_nodes.find(node)]
	changed_node.x = to.x
	changed_node.y = to.y
	save_properties()

func load_recipes() -> void:
	recipe_strings.clear()
	recipes.clear()
	recipe_strings = Utility.load_path("res://resources/recipes")
	load_gadgets()
	load_items()
	load_emails()
	if !recipe_strings.is_empty():
		for recipe_string in recipe_strings:
			recipes.append(load(recipe_string))
	for recipe in recipes:
		if properties.recipe_nodes.filter(func(recipe_node): return recipe_node.recipe == recipe).is_empty():
			# If there does not exist a recipe node for the given recipe
			add_recipe(recipe)
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
				recipe_node.gadget_node = add_gadget(recipe.gadget)
		if !recipe.inputs.is_empty():
			for slot:Slot in recipe.inputs:
				if slot != null:
					var item:Item = slot.item
					if item in items:
						if properties.item_nodes.filter(func(item_node): return item_node.item == item).is_empty():
							recipe_node.input_item_nodes.append(add_item(item))
		if !recipe.outputs.is_empty():
			for slot:Slot in recipe.outputs:
				var item:Item = slot.item
				if item in items:
					if properties.item_nodes.filter(func(item_node): return item_node.item == item).is_empty():
						recipe_node.output_item_nodes.append(add_item(item))

func load_gadgets() -> void:
	gadget_strings.clear()
	gadgets.clear()
	gadget_strings = Utility.load_path("res://resources/gadgets")
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
			remove_gadgets.append(index)
	for index in range(remove_gadgets.size()):
		properties.gadget_nodes.remove_at(remove_gadgets[index] - index) # by minusing by the index, we account for the index shifting down every removal
	if !remove_gadgets.is_empty():
		save_properties() # only save if items were removed, to avoid infinite loops
		
func load_items() -> void:
	item_strings.clear()
	items.clear()
	item_strings = Utility.load_path("res://resources/items")
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
			remove_items.append(index) # can't remove while iterating through list
	for index in range(remove_items.size()):
		properties.item_nodes.remove_at(remove_items[index] - index) # by minusing by the index, we account for the index shifting down every removal
	if !remove_items.is_empty():
		save_properties() # only save if items were removed, to avoid infinite loops

func load_emails() -> void:
	email_strings.clear()
	emails.clear()
	email_strings = Utility.load_path("res://resources/emails")
	if !email_strings.is_empty():
		for email_string in email_strings:
			emails.append(load(email_string))
	for email in emails:
		if properties.email_nodes.filter(func(email_node): return email_node.email == email).is_empty():
			# If there does not exist an email node for the given email
			add_email(email)
	for index in range(properties.email_nodes.size()):
		# validate if email exists
		var email_node:EmailEditorNode = properties.email_nodes[index]
		var email:Email = email_node.email
		if email not in emails:
			properties.email_nodes.remove_at(index)
			save_properties()
			continue
		if !email.prerequisite_emails.is_empty():
			for prerequisite_email:Email in email.prerequisite_emails:
				if prerequisite_email != null:
					if prerequisite_email in emails:
						if properties.email_nodes.filter(func(email_node): return email_node.email == prerequisite_email).is_empty():
							properties.email_nodes.append(add_email(email))
	
func add_recipe(_recipe:Recipe) -> RecipeEditorNode:
	var new_recipe:RecipeEditorNode = RecipeEditorNode.new()
	new_recipe.x = 100
	new_recipe.y = 100
	new_recipe.recipe = _recipe
	new_recipe.gadget_node = null
	properties.recipe_nodes.append(new_recipe)
	save_properties()
	return new_recipe

func add_gadget(gadget:Gadget) -> GadgetEditorNode:
	var new_gadget:GadgetEditorNode = GadgetEditorNode.new()
	var center_pos:Vector2 = Vector2(graph_edit.scroll_offset + graph_edit.size / 2) / graph_edit.zoom
	new_gadget.x = center_pos.x
	new_gadget.y = center_pos.y
	new_gadget.gadget = gadget
	properties.gadget_nodes.append(new_gadget)
	save_properties()
	return new_gadget

func add_item(item:Item) -> ItemEditorNode:
	var new_item:ItemEditorNode = ItemEditorNode.new()
	var center_pos:Vector2 = Vector2(graph_edit.scroll_offset + graph_edit.size / 2) / graph_edit.zoom
	new_item.x = center_pos.x
	new_item.y = center_pos.y
	new_item.item = item
	properties.item_nodes.append(new_item)
	save_properties()
	return new_item
	
func add_email(email:Email) -> EmailEditorNode:
	var new_email:EmailEditorNode = EmailEditorNode.new()
	var center_pos:Vector2 = Vector2(graph_edit.scroll_offset + graph_edit.size / 2) / graph_edit.zoom
	new_email.x = center_pos.x
	new_email.y = center_pos.y
	new_email.email = email
	properties.email_nodes.append(new_email)
	save_properties()
	return new_email
	
func remove_node(_node:GraphNode):
	var connections:Array = graph_edit.get_connection_list().filter(func(connection): return connection.from_node == _node.get_name())
	if !connections.is_empty():
		for connection in connections:
			_on_disconnect_request(connection.from_node, connection.from_port, connection.to_node, connection.to_port) # Simulate a disconnection
	
	if "recipe_node" in _node:
		var to_delete = properties.recipe_nodes.filter(func(recipe_node): return recipe_node == _node.recipe_node)[0]
		properties.recipe_nodes.remove_at(properties.recipe_nodes.find(to_delete))
	elif "item_node" in _node:
		var to_delete = properties.item_nodes.filter(func(item_node): return item_node == _node.item_node)[0]
		properties.item_nodes.remove_at(properties.item_nodes.find(to_delete))
	elif "gadget_node" in _node:
		var to_delete = properties.gadget_nodes.filter(func(gadget_node): return gadget_node == _node.gadget_node)[0]
		properties.gadget_nodes.remove_at(properties.gadget_nodes.find(to_delete))
	save_properties()
	graph_edit.clear_connections()

func populate_menu_items():
	clear_menu(item_menu)
	
	for item:Item in items:
		item_menu.add_item(item.name)
		
func populate_menu_gadgets():
	clear_menu(gadget_menu)

	for gadget:Gadget in gadgets:
		gadget_menu.add_item(gadget.name)
		
func item_menu_pressed(index:int):
	if index == 0:
		item_popup = item_popup_scene.instantiate()
		control.add_child(item_popup)
		item_popup.show()
		item_popup.find_child("Confirm", true).pressed.connect(add_named_item)
	else:
		var item = items.filter(func(item): return item.name == item_menu.get_item_text(index))[0]
		add_item(item)
	
func gadget_menu_pressed(index:int):
	if index == 0:
		gadget_popup = gadget_popup_scene.instantiate()
		control.add_child(gadget_popup)
		gadget_popup.show()
		gadget_popup.find_child("Confirm", true).pressed.connect(add_named_gadget)
	else:
		var gadget = gadgets.filter(func(gadget): return gadget.name == gadget_menu.get_item_text(index))[0]
		add_gadget(gadget)

func add_named_item():
	var item_name:String = "generated_item"
	item_name = item_popup.find_child("Name").get_text()
	var new_item:Item = Item.new()
	new_item.set_name(item_name)
	new_item.name = item_name
	var path:String = "res://resources/items/" + new_item.get_name() + ".tres"
	ResourceSaver.save(new_item, path)
	new_item.take_over_path(path)
	add_item(new_item)
	item_popup.hide()	
	load_items()
	
func add_named_gadget():
	var gadget_name:String = "generated_gadget"
	gadget_name = gadget_popup.find_child("Name").get_text()
	var new_gadget:Gadget = Gadget.new()
	new_gadget.set_name(gadget_name)
	new_gadget.name = gadget_name
	new_gadget.item = Item.new()
	var path:String = "res://resources/gadgets/" + new_gadget.get_name() + ".tres"
	ResourceSaver.save(new_gadget, path)
	new_gadget.take_over_path(path)
	add_gadget(new_gadget)
	gadget_popup.hide()
	load_gadgets()

func clear_menu(menu):
	var to_remove:Array[int]
	for index in range(menu.get_item_count()):
		if index > 1:
			# Clear all except the first two, which are Create new... and a seperator
			to_remove.append(index)
			
	for index in range(to_remove.size()):
		var remove_index:int = to_remove[index]
		menu.remove_item(remove_index - index)

func save_properties() -> void:
	ResourceSaver.save(properties, properties.get_path())
	properties.take_over_path(properties.get_path())

func _exit_tree() -> void:
	control.free()
