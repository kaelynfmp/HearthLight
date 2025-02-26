@tool
extends Control

@export var scale_factor:float = 1
@onready var scale_factor_node:Node2D = $ScaleFactor

func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	scale_factor_node.scale = Vector2(scale_factor, scale_factor)
