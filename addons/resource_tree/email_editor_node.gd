@tool
class_name EmailEditorNode

extends Resource

signal order_currency_changed

var prev_currency:int = 0
@export var email:Email:
	get:
		if email != null and email.attached_order != null:
			if email.attached_order.currency_reward != prev_currency:
				prev_currency = email.attached_order.currency_reward
				order_currency_changed.emit()
		return email
@export var x:int
@export var y:int
var prev_prerequisite_email_nodes_size:int = 0
@export var prerequisite_email_nodes:Array[EmailEditorNode]
@export var required_item_nodes:Dictionary[Resource, int]:
	get:
		if email.attached_order == null:
			required_item_nodes.clear()
			return required_item_nodes
		
		return required_item_nodes
@export var given_item_nodes:Dictionary[Resource, int]:
	get:
		if email.attached_order == null:
			given_item_nodes.clear()
			return given_item_nodes

		return given_item_nodes
@export var rewards_item_nodes:Dictionary[Resource, int]:
	get:
		if email.attached_order == null:
			rewards_item_nodes.clear()
			return rewards_item_nodes

		return rewards_item_nodes

func _init(p_email:Email = null, p_x:int = 0, p_y:int = 0, p_prerequisite_email_nodes:Array[EmailEditorNode] = [], p_required_item_nodes:Dictionary[Resource, int] = {}, \
	p_given_item_nodes:Dictionary[Resource, int] = {}, p_rewards_item_nodes:Dictionary[Resource, int] = {}):
	email = p_email
	x = p_x
	y = p_y
	prerequisite_email_nodes = p_prerequisite_email_nodes
	required_item_nodes = p_required_item_nodes
	given_item_nodes = p_given_item_nodes
	rewards_item_nodes = p_rewards_item_nodes
	
func _order_currency_changed():
	order_currency_changed.emit()

func clear_order() -> void:
	email.attached_order = null
	save_email()

func save_email():
	if email != null:
		ResourceSaver.save(email, email.get_path())
		email.take_over_path(email.get_path())

func add_order():
	email.attached_order = Order.new()
	save_email()