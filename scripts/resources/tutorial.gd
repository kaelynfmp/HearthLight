@tool

@icon("res://resources/resource-icons/tutorial.svg")

class_name Tutorial

extends Resource

## Signal that emits on tutorial completing
signal completed

## Signal that indicates the tutorial is currently active
signal activated

## Title of the tutorial
@export var title: String
var prev_steps
## Current [TutorialStep]'s of the tutorial
@export var steps: Array[TutorialStep]:
	get:
		if prev_steps != steps:
			for index in range(steps.size()):
				var step:TutorialStep = steps[index]
				if step is TutorialStep and "completed" in step:
					if not step.completed.is_connected(step_completed):
						step.completed.connect(step_completed)
				else:
					steps[index] = TutorialStep.new()
			prev_steps = steps.duplicate()
		return steps

## The currently 'active' step for visualization purpoes
var active_step:TutorialStep
## Whether or not the tutorial is complete
var complete: bool:
	set(value):
		var old_complete:bool = complete
		complete = value
		if value == true and old_complete == false:
			completed.emit()
var active:bool:
	set(value):
		var old_active:bool = active
		active = value
		if value == true and old_active == false:
			activated.emit()
## The script that will check for when a tutorial is active, and activated it if so
@export var activation_script:GDScript
## The node containing the activation script
var activation_script_node:Node

func _init(p_title:String = "", p_steps: Array[TutorialStep] = [], p_active_step:TutorialStep = null, p_complete:bool = false, \
p_activation_script:GDScript = null, p_activation_script_node:Node = null) -> void:
	title = p_title
	steps = p_steps
	active_step = p_active_step
	complete = p_complete
	activation_script = p_activation_script
	activation_script_node = p_activation_script_node
	
## Whenever a step is completed, it will check if the entire tutorial is complete. If it is, emit signal and set self to complete
func step_completed():
	if not Engine.is_editor_hint():
		TutorialManager.tutorial_sprite.sprite = null
	if steps.all(func(step:TutorialStep): return step.complete):
		complete = true
	else:
		active_step.active = false
		active_step = steps.filter(func(step:TutorialStep): return step != active_step and not step.complete)[0]
		active_step.active = true
