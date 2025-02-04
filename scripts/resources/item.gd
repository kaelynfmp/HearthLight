@icon("res://resources/resource-icons/item.svg")

class_name Item

extends Resource

## Icon that represents the sprite in-game.
@export var sprite: Texture2D
## Name of the item as it appears in-game.
@export var name: String
## In-game description of item.
@export_multiline var description: String

@export_category("Properties")
## Maximum amount of items that can be stored in one inventory slot.
@export_range(1, 999) var maxStack: int
## Price of an item if you were to sell it as junk. Purchase prices are determined algorithmically based off of this value.
@export_range(0, 999999999999999999) var price: int

## Initialization of the default values
func _init(p_sprite = null, p_name = "", p_desc = "", p_maxStack = 999, p_price = 0):
	sprite = p_sprite
	name = p_name
	description = p_desc
	maxStack = p_maxStack
	price = p_price
