extends StaticBody2D
@export var item: Item
@export var move_speed: int = 200
@export var target_position: Vector2 = Vector2(-100, -100)
func _ready() -> void:
	$CollisionShape2D/Sprite2D.texture = item.texture
func _process(delta: float) -> void:
	if target_position != Vector2(-100, -100):
		global_position = global_position.move_toward(target_position, move_speed * delta)
