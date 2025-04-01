extends Node

var tutorial:Tutorial

func _physics_process(_delta: float) -> void:
	if get_tree().current_scene != null and get_tree().current_scene.name == "Room":
		tutorial.active = true
