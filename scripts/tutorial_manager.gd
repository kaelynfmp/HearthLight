extends Node

@export var tutorials:Array[Tutorial]
var current_tutorial:Tutorial
var tutorial_sprite:Sprite2D

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
	tutorial.activation_script_node.tutorial = tutorial
	add_child(tutorial.activation_script_node)
	
## Load all of the steps in a tutorial into a scene
func load_steps(tutorial:Tutorial):
	tutorial.activation_script_node.queue_free()
	tutorial.activation_script_node = null
	for step:TutorialStep in tutorial.steps:
		if step == tutorial.steps[0]:
			step.active = true
		if step.step_script != null:
			step.step_script_node = step.step_script.new()
			step.step_script_node.step = step
			add_child(step.step_script_node)
			step.completed.connect(step_complete_delete_node.bind(step))
			
## Sets the 'tutorial sprite', which is the overlay for things highlighted by the tutorial
func set_tutorial_sprite(sprite:Sprite2D):
	tutorial_sprite = sprite