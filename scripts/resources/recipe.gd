@icon("res://resources/resource-icons/recipe.svg")

class_name Recipe

extends Resource

## Gadget this recipe uses
@export var gadget: Gadget
## Inputs this recipe takes
@export var inputs: Array[Item]
## Outputs of this recipe
@export var outputs: Array[Item]
## Processing time multiplier of this recipe
@export var processing_multiplier: float

func _init(p_gadget: Gadget = null, p_inputs: Array[Item] = [], p_outputs: Array[Item] = [], p_processing_multiplier: float = 1.0):
	gadget = p_gadget
	inputs = p_inputs
	outputs = p_outputs
	processing_multiplier = p_processing_multiplier