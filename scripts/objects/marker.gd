extends Node2D

@export var is_generator = false
@export var is_uni_generator = false

var coords : PackedVector2Array = [
	Vector2(0, -16), Vector2(-32, 0),
	Vector2(0, 16), Vector2(32, 0),
]

var generator_coords : PackedVector2Array = [
	Vector2(0, -84), Vector2(-168, 0),
	Vector2(0, 84), Vector2(168, 0),
]

var uni_generator_coords : PackedVector2Array = [
	Vector2(0, -184), Vector2(-368, 0),
	Vector2(0, 184), Vector2(368, 0),
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
			
func _draw() -> void:
	draw_polygon(uni_generator_coords if is_uni_generator else generator_coords if is_generator else coords, 
	[
		Color(1., 1., 0.0, 0.4) if is_generator or is_uni_generator else Color(1.0, 1.0, 1.0, 0.4)
	])
