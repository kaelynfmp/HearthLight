extends StaticBody2D

@onready var gadget_stats = load("res://resources/gadgets/wheel.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.texture = gadget_stats.texture
	$Timer.wait_time = gadget_stats.process_time
	$Timer.start()
	$TextureProgressBar.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$TextureProgressBar.value = 100 - ($Timer.time_left / $Timer.wait_time) * 100
