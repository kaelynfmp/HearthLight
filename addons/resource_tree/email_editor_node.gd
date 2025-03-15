@tool
class_name EmailEditorNode

extends Resource

@export var email:Email
@export var x:int
@export var y:int
var prev_prerequisite_email_nodes_size:int = 0
@export var prerequisite_email_nodes:Array[EmailEditorNode]
var prev_order_input_nodes_size:int = 0
@export var order_input_nodes:Array[Resource]:
	get:
		if prev_order_input_nodes_size != order_input_nodes.size():
			prev_order_input_nodes_size = order_input_nodes.size()
			changed.emit()
			if email != null:
				var order = email.order
				if order != null:
					order.required_items = []
					for index in range(order_input_nodes.size()):
						var order_input_node:Resource = order_input_nodes[index]
						order.required_items[index] = order_input_node.gadget if "gadget" in order_input_node else order_input_node.item
					save_email()
		return order_input_nodes
var prev_order_input_quantities:Array[int] = []
@export var order_input_quantities:Array[int]:
	get:
		if prev_order_input_quantities != order_input_quantities:
			prev_order_input_quantities = order_input_quantities
			changed.emit()
			if email != null:
				var order = email.order
				if order != null:
					order.required_quantities = []
					for index in range(order_input_quantities.size()):
						var order_input_quantity:int = order_input_quantities[index]
						order.required_quantities[index] =order_input_quantity
					save_email()
		return order_input_quantities

var prev_order_output_nodes_size:int = 0
@export var order_output_nodes:Array[Resource]:
	get:
		if prev_order_output_nodes_size != order_output_nodes.size():
			prev_order_output_nodes_size = order_output_nodes.size()
			changed.emit()
			if email != null:
				var order = email.order
				if order != null:
					order.given_items = []
					for index in range(order_output_nodes.size()):
						var order_output_node:Resource = order_output_nodes[index]
						order.given_items[index] = order_output_node.gadget if "gadget" in order_output_node else order_output_node.item
					save_email()
		return order_output_nodes
var prev_order_output_quantities:Array[int] = []
@export var order_output_quantities:Array[int]:
	get:
		if prev_order_output_quantities != order_output_quantities:
			prev_order_output_quantities = order_output_quantities
			changed.emit()
			if email != null:
				var order = email.order
				if order != null:
					order.required_quantities = []
					for index in range(order_output_quantities.size()):
						var order_output_quantity:int = order_output_quantities[index]
						order.given_quantities[index] = order_output_quantity
					save_email()
		return order_output_quantities

func _init(p_email:Email = null, p_x:int = 0, p_y:int = 0, p_prerequisite_email_nodes:Array[EmailEditorNode] = [],
p_order_input_nodes:Array[Resource] = [], p_order_input_quantities:Array[int] = [], p_order_output_nodes:Array[Resource] = [],
p_order_output_quantities:Array[int] = []):
	email = p_email
	x = p_x
	y = p_y
	prerequisite_email_nodes = p_prerequisite_email_nodes
	order_input_nodes = p_order_input_nodes
	order_input_quantities = p_order_input_quantities
	order_output_nodes = p_order_output_nodes
	order_output_quantities = p_order_output_quantities

func clear_order() -> void:
	email.order = null
	# We also clear all of the item nodes, as clearing the gadget removes all inputs and outputs
	var clear_input_nodes:Array
	for index in range(order_input_nodes.size()):
		clear_input_nodes.append(index)

	for index in range(clear_input_nodes.size()):
		clear_order_input_node(order_input_nodes[clear_input_nodes[index] - index])

	var clear_output_nodes:Array
	for index in range(order_output_nodes.size()):
		clear_output_nodes.append(index)

	for index in range(clear_output_nodes.size()):
		clear_order_output_node(order_output_nodes[clear_output_nodes[index] - index])

func clear_order_input_node(item_node) -> void:
	order_input_nodes.remove_at(order_input_nodes.find(item_node))

func clear_order_output_node(item_node) -> void:
	order_output_nodes.remove_at(order_output_nodes.find(item_node))

func save_email():
	if email != null:
		ResourceSaver.save(email, email.get_path())
		email.take_over_path(email.get_path())