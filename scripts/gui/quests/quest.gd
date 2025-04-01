extends VBoxContainer

## If this quest is associated with an order, this is the order
var order:Order
var email:Email
@onready var step_scene:PackedScene = preload("res://scenes/quests/step_container.tscn")

func _ready() -> void:
	if order:
		if OrderManager.email_by_order[order]:
			email = OrderManager.email_by_order[order]
		if email:
			Utility.set_truncated_text(email.subject, $QuestLabel/QuestTitle)
		
		for child in $Steps.get_children():
			child.queue_free()
		
		for required_item in order.required_items:
			var step:MarginContainer = step_scene.instantiate()
			step.required_item = required_item
			step.required_quantity = order.required_quantities[order.required_items.find(required_item)]
			$Steps.add_child(step)
