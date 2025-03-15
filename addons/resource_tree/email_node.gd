@tool
extends GraphNode

@onready var email_node:EmailEditorNode
signal moved(to:Vector2, recipe_node:RecipeEditorNode)
signal kill(node:GraphNode)

@onready var spinbox:PackedScene

var container:Control
var panel:Panel
var order_container:Control
var add_order:TextureButton
var remove_order:TextureButton

func _ready():
	container = find_child("EmailContainer")
	panel = container.find_child("Panel")
	order_container = container.find_child("OrderContainer")
	add_order = panel.find_child("AddOrder")
	remove_order = panel.find_child("RemoveOrder")
	spinbox = load("res://addons/resource_tree/spin_box.tscn")

func _process(_delta: float) -> void:
	if email_node == null or email_node.email == null:
		return
	var email:Email = email_node.email
	if container == null:
		return
	var sender_label:RichTextLabel = container.find_child("Sender")
	Utility.set_truncated_text(email.sender, sender_label)
	var subject_label:RichTextLabel = container.find_child("Subject")
	Utility.set_truncated_text(email.subject, subject_label)
	var blurb_label:RichTextLabel = container.find_child("Blurb")
	Utility.set_truncated_text(email.contents.split("\n")[0], blurb_label)
	
	
	var content_label:RichTextLabel = panel.find_child("Content")
	content_label.text = email.contents
	var sender_dropdown_label:RichTextLabel = panel.find_child("SenderDropdown")
	Utility.set_truncated_text(email.sender, sender_dropdown_label)
	var subject_dropdown_label:RichTextLabel = panel.find_child("SubjectDropdown")
	Utility.set_truncated_text(email.subject, subject_dropdown_label)
	
	if order_container == null or add_order == null or remove_order == null:
		return
	var order_exists:bool = !email_node.required_item_nodes.is_empty() or !email_node.given_item_nodes.is_empty() or \
	!email_node.rewards_item_nodes.is_empty()
	remove_order.set_visible(order_exists)
	add_order.set_visible(!order_exists)
	order_container.set_visible(order_exists)
	if !order_exists: return
	var fill_items := func(items:HFlowContainer, nodes:Dictionary[Resource, int], slot_type:String, prefix:String):
		var item_in_nodes:bool = items.get_children().all(func(child): return \
		false if !child.get_child(0).slot.item else \
		nodes.keys().any(func(node): return ((node.gadget.name == child.get_child(0).slot.item.name) \
		if node is GadgetEditorNode else (node.item.name if node.item else false))))
		if items.get_child_count() != nodes.size() or !item_in_nodes:
			for child in items.get_children(): # Remove all children
				child.queue_free()
	
			var index:int = 0
			for node in nodes.keys():
				var item:Item = node.gadget.item if node is GadgetEditorNode else node.item
				var slot:Slot = Slot.new(item, nodes[node], true)
				var new_control:Control = Control.new()
				var new_slot:PanelContainer = load("res://scenes/inventory/" + slot_type + "_slot.tscn").instantiate()
				new_slot.set_slot(slot)
				new_slot.update()
				new_slot.set_name(prefix + str(index))
				new_slot.set_scale(Vector2(0.5, 0.5))
				new_control.set_custom_minimum_size(316 * new_slot.get_scale())
				var spinbox_node:SpinBox = spinbox.instantiate()
				spinbox_node.slot = slot
				spinbox_node.set_value(slot.quantity)
				spinbox_node.connect_slot()
				new_slot.find_child("Stack").set_z_index(-1)
				new_slot.find_child("SlotPanel").add_child(spinbox_node)
				new_control.add_child(new_slot)
				items.add_child(new_control)
				index += 1
	
	var given_items:HFlowContainer = order_container.find_child("GivenItems", true)
	fill_items.call(given_items, email_node.given_item_nodes, "given", "GivenItemSlot")
			
	var required_items:HFlowContainer = order_container.find_child("RequiredItems", true)
	fill_items.call(required_items, email_node.required_item_nodes, "input", "RequiredItemSlot")

	var rewards_items:HFlowContainer = order_container.find_child("RewardsItems", true)
	fill_items.call(rewards_items, email_node.rewards_item_nodes, "output", "RewardsItemSlot")

	var rewards_currency:LineEdit = order_container.find_child("CurrencyLabel", true)
	if rewards_currency.text == "":
		rewards_currency.set_text(str(email_node.email.attached_order.currency_reward))
	
	
func _on_dragged(from:Vector2, to:Vector2) -> void:
	moved.emit(to, email_node)

func _on_delete_button_pressed() -> void:
	kill.emit(self)
	var dir: DirAccess = DirAccess.open("res://resources/emails")
	dir.remove(email_node.email.get_path())
	moved.emit(Vector2.ZERO, email_node) # Sends the move signal to tell the recipe tree immediately to check if it is alive
	EditorInterface.get_resource_filesystem().scan()

func _on_node_selected() -> void:
	EditorInterface.edit_resource(email_node.email)