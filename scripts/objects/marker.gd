extends Node2D

@export var size := Vector2.ONE * 300.0
@export var color := Color(1.0, 1.0, 0.0, 0.5)

var coords : PackedVector2Array = [
	Vector2(0, -16), Vector2(-32, 0),
	Vector2(0, 16), Vector2(32, 0),
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
			
func _draw() -> void:
	draw_polygon(coords, [Color(1.0, 1.0, 1.0, 0.4)])
