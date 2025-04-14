extends Control

@export var curve:Path2D
@export var line:Line2D

func _ready():
	line.clear_points()
	for point in curve.curve.get_baked_points():
		line.add_point(point + curve.position)