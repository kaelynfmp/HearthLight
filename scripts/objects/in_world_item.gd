extends RigidBody2D
@export var item: Item
func _ready() -> void:
	$CollisionShape2D/Sprite2D.texture = item.texture
