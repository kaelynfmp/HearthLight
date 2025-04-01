@icon("res://resources/resource-icons/step.svg")

class_name TutorialStep

extends Resource

signal completed

## A unique ID that the StepManager will use to check for the steps completeness
@export_multiline var desc:String
## A script that, internally, will handle things the step needs to do
@export var step_script:GDScript
## The node the step script is running on
var step_script_node:Node 
var complete:bool
var active:bool

func _init(p_desc:String = "", p_complete:bool = false, p_step_script:GDScript = null, p_step_script_node:Node = null, p_active:bool = false) -> void:
	desc = p_desc
	complete = p_complete
	step_script = p_step_script
	step_script_node = p_step_script_node
	active = p_active