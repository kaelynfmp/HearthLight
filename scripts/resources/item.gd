@icon("res://resources/resource-icons/item.svg")

class_name Item

extends Resource

@export var sprite: Texture2D
@export var name: String
@export_multiline var desc: String
@export var maxStack: int
@export var price: int

# Make sure that every parameter has a default value.
# Otherwise, there will be problems with creating and editing
# your resource via the inspector.
func _init(p_sprite = null, p_name = "", p_desc = "", p_maxStack = 0, p_price = 0):
	sprite = p_sprite
	name = p_name
	desc = p_desc
	maxStack = p_maxStack
	price = p_price
