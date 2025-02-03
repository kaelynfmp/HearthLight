extends Node2D

@export var size := Vector2.ONE * 128.0
@export var color := Color(1.0, 1.0, 0.0, 0.5)

var coords : Array = [
	[0, -16],  [-32, 0],
	[0, 16], [32, 0],
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _draw() -> void:
	var array : PackedVector2Array = []
	for coord in coords:
		array.append(Vector2(coord[0], coord[1]))
	draw_polygon(array, [Color(1.0, 1.0, 1.0, 0.4)])
	
