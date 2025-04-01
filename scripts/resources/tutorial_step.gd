@icon("res://resources/resource-icons/step.svg")

class_name TutorialStep

extends Resource

signal completed

@export var desc:String
var complete:bool

func _init(p_desc:String = "", p_complete:bool = false) -> void:
	desc = p_desc
	complete = p_complete