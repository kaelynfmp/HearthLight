extends AnimatedSprite2D

var teleporter:InWorldGadget

func _process(_delta: float) -> void:
	if GameManager.gadget == null or teleporter == null:
		sprite_frames = null
		visible = false
		return
		
	visible = true
	var sprite:AnimatedSprite2D = teleporter.find_child("Sprite")
	sprite_frames = sprite.sprite_frames
	animation = sprite.animation
	offset = sprite.offset
	set_position(sprite.get_global_transform_with_canvas().get_origin()) # Find better way than hardcoding later
	set_scale(teleporter.get_global_transform_with_canvas().get_scale() * sprite.get_scale())