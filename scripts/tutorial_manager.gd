extends Node

@export var tutorials:Array[Tutorial]
var current_tutorial:Tutorial

func _ready():
	for tutorial:Tutorial in tutorials:
		if tutorial == tutorials[0]:
			current_tutorial = tutorial
			tutorial_queued(current_tutorial)
				
## Delete the node containing the step script (that checks if the tutorial step has been completed)
## when the step is completed
func step_complete_delete_node(step:TutorialStep):
	step.step_script_node.queue_free()
	step.step_script_node = null
	
## When a tutorial is queued, activate its script, and get ready for its activation
func tutorial_queued(tutorial:Tutorial):
	# Bind the tutorial activating to loading the steps
	tutorial.activated.connect(load_steps.bind(tutorial))
	tutorial.activation_script_node = tutorial.activation_script.new()
	add_child(tutorial.activation_script_node)
	
## Load all of the steps in a tutorial into a scene
func load_steps(tutorial:Tutorial):
	tutorial.activation_script_node.queue_free()
	tutorial.activation_script_node = null
	for step:TutorialStep in tutorial.steps:
		if step.step_script != null:
			step.step_script_node = step.step_script.new()
			add_child(step.step_script_node)
			step.completed.connect(step_complete_delete_node.bind(step))