extends VBoxContainer

@onready var quest_scene:PackedScene = preload("res://scenes/quests/quest.tscn")
@onready var quest_step_scene:PackedScene = preload("res://scenes/quests/step_container.tscn")

func _ready() -> void:
	for child in get_children():
		child.queue_free()
	OrderManager.order_accepted.connect(order_accepted)

func order_accepted(order:Order):
	var new_quest:VBoxContainer = quest_scene.instantiate()
	new_quest.order = order
	add_child(new_quest)
	order.completed.connect(order_completed.bind(new_quest))
	order.removed.connect(order_completed.bind(new_quest))
	
func order_completed(quest:VBoxContainer):
	remove_child(quest)
