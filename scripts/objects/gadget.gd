extends StaticBody2D

@onready var gadget_stats = load("res://resources/gadgets/wheel.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.texture = gadget_stats.texture
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
