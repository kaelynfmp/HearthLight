@tool
class_name GadgetEditorNode

extends Resource

signal cleared

@export var gadget:Gadget
@export var x:int
@export var y:int

func _init(p_gadget:Gadget = null, p_x:int = 0, p_y:int = 0):
	gadget = p_gadget
	x = p_x
	y = p_y
	
func clear():
	cleared.emit()