extends Node
var computer_instance = null
@onready var computer_scene = preload("res://scenes/Computer Scenes/computer_interface.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_computer"):
		toggle_computer()

func toggle_computer():
	if computer_instance: # trying to close computer
		GameManager.in_computer = false
		computer_instance.parent_node = null
		computer_instance.queue_free()
		computer_instance = null
	else:
		GameManager.in_computer = true
		computer_instance = computer_scene.instantiate()
		computer_instance.parent_node = self
		get_tree().current_scene.add_child(computer_instance)
