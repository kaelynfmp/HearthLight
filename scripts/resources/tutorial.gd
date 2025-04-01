@icon("res://resources/resource-icons/tutorial.svg")

class_name Tutorial

extends Resource

## Signal that emits on tutorial completing
signal completed

## Title of the tutorial
@export var title: String
var prev_steps
## Current [TutorialStep]'s of the tutorial
@export var steps: Array[TutorialStep]:
	get:
		if prev_steps != steps:
			for step in steps:
				if not step.completed.is_connected(step_completed):
					step.completed.connect(step_completed)
		return steps
## Whether or not the tutorial is complete
var complete: bool

func _init(p_title:String = "", p_steps: Array[TutorialStep] = [], p_complete:bool = false) -> void:
	title = p_title
	steps = p_steps
	complete = p_complete
	
## Whenever a step is completed, it will check if the entire tutorial is complete. If it is, emit signal and set self to complete
func step_completed():
	if steps.all(func(step:TutorialStep): return step.complete):
		complete = true
		completed.emit()