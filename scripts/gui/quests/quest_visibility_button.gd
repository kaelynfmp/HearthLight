extends TextureButton

@export var close:bool

func _process(_delta: float) -> void:
	visible = GameManager.quest_list_visible if close else !GameManager.quest_list_visible
	if OrderManager.accepted_orders.filter(func(order:Order): return not order.is_completed).is_empty():
		visible = false

func _on_pressed() -> void:
	GameManager.quest_list_visible = !GameManager.quest_list_visible
