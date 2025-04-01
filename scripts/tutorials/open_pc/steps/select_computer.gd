extends Node

var step:TutorialStep
var selected_sprite:AnimatedSprite2D

func _ready() -> void:
	var gadgets: Array[Node] = get_tree().get_nodes_in_group("world_gadgets")
	var computer:Node = gadgets[gadgets.find_custom(func(gadget): return "gadget_stats" in gadget and gadget.gadget_stats.name == "Computer")]
	selected_sprite = computer.find_child("Sprite")
	TutorialManager.tutorial_sprite.sprite = selected_sprite

func _physics_process(_delta: float) -> void:
	if selected_sprite == null:
		var gadgets: Array[Node] = get_tree().get_nodes_in_group("world_gadgets")
		var computer_find:int = gadgets.find_custom(func(gadget): return "gadget_stats" in gadget and gadget.gadget_stats.name == "Computer")
		if computer_find != -1:
			var computer:Node = gadgets[computer_find]
			selected_sprite = computer.find_child("Sprite")
			TutorialManager.tutorial_sprite.sprite = selected_sprite
	if GameManager.computer_visible:
		step.complete = true
