@icon("res://resources/resource-icons/inventory.svg")

class_name Inventory

extends Resource

@export var items : Array[Item]

## Initialization of the default values
func _init(p_items = []):
	items = p_items