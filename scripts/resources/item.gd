@icon("res://resources/resource-icons/item.svg")

class_name Item

extends Resource

## Icon that represents the sprite in-game.
@export var texture: Texture2D
## Name of the item as it appears in-game.
@export var name: String
## In-game description of item.
@export_multiline var description: String

@export_category("Properties")
## Maximum amount of items that can be stored in one inventory slot.
@export_range(1, GameManager.Items.MAX_STACK) var max_stack: int = GameManager.Items.DEFAULT_STACK
## Price of an item if you were to sell it as junk. Purchase prices are determined algorithmically based off of this value.
@export_range(0, GameManager.Items.MAX) var price: int

## Initialization of the default values
func _init(p_texture = null, p_name = "", p_desc = "", p_max_stack = GameManager.Items.DEFAULT_STACK, p_price = 0):
	texture = p_texture
	name = p_name
	description = p_desc
	max_stack = p_max_stack
	price = p_price
