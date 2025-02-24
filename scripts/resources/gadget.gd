@icon("res://resources/resource-icons/gadget.svg")

class_name Gadget

extends Resource

## Texture that represents the sprite in-game.
@export var texture: Texture2D
## Name of the gadget as it appears in-game.
@export var name: String
## In-game description of the gadget.
@export_multiline var description: String

@export_category("Properties")
## Item corresponding ot the gadget for inventory usage
@export var item: Item
## Inventory that belongs to the gadget
@export var inventory: Inventory
## Whether or not this gadget can have recipes
@export var produces: bool
## The amount of inputs a recipe from this gadget can take
@export var inputs: int
## The amount of outputs this gadget can produce
@export var outputs: int
## The amount of time it takes to process a recipe
@export var process_time: float

func _init(p_texture: Texture2D = null, p_name: String = "", p_description: String = "", p_item: Item = null, \
		   p_inventory: Inventory = null, p_produces: bool = false, p_inputs: int = 0, p_outputs: int = 0, \
		   p_process_time: float = 0.0):
	texture = p_texture
	name = p_name
	description = p_description
	item = p_item
	inventory = p_inventory
	produces = p_produces
	inputs = p_inputs
	outputs = p_outputs
	process_time = p_process_time
