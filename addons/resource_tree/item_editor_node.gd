@tool
class_name ItemEditorNode

extends Resource

@export var item:Item
@export var x:int
@export var y:int

func _init(p_item:Item = null, p_x:int = 0, p_y:int = 0):
	item = p_item
	x = p_x
	y = p_y