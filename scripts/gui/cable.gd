extends Node2D

class_name Cable

@onready var origin:MeshInstance2D = $Origin
@onready var end:MeshInstance2D = $End
@onready var curve:Path2D = $Curve
@onready var line:Line2D = $Line
@onready var prev_end_position:Vector2 = Vector2(end.position)
@export var origin_position:Vector2
@export var end_position:Vector2
@export var curve_intensity:int = 300
@export var max_curve_distance:int = 200
@export var closeness_factor:float = 2.0
@export var locked_to_mouse:bool = false
@export var colour:Color
var curve_x:float = 0
var curve_y:float = 0

func _ready() -> void:
	origin.position = origin_position
	end.position = end_position
	var origin_texture:GradientTexture1D = origin.texture
	origin_texture.gradient.colors = PackedColorArray([colour])
	var end_texture:GradientTexture1D = end.texture
	end_texture.gradient.colors = PackedColorArray([colour])
	line.default_color = colour
	
func _process(delta: float) -> void:
	if locked_to_mouse:
		end.position = get_viewport().get_mouse_position()
	if (end.position != prev_end_position):
		prev_end_position = end.position
		var distance_ratio:Vector2 = Vector2(
			clamp((origin.position.x - end.position.x) / max_curve_distance, -1, 1),
			clamp((origin.position.y - end.position.y) / max_curve_distance, -1, 1)
		)
		var closeness_x = min(abs(origin.position.x - end.position.x) / 200.0, closeness_factor) # Normalize to 1
		var closeness_y = min(abs(origin.position.x - end.position.x) / 200.0, closeness_factor)
		var closeness = min(closeness_x, closeness_y) / closeness_factor
		var curve_intensity_factor = curve_intensity * closeness
		curve.curve.set_point_position(0, origin.position)
		curve_x = curve_intensity_factor * distance_ratio.x
		curve_y = curve_intensity_factor * distance_ratio.y
		curve.curve.set_point_out(0, Vector2(-curve_x, curve_y))
		curve.curve.set_point_position(1, end.position)
		curve.curve.set_point_in(1, Vector2(curve_x, -curve_y))
		line.clear_points()
		for point in curve.curve.get_baked_points():
				line.add_point(point + curve.position)
