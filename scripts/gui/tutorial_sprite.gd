extends AnimatedSprite2D

var sprite:AnimatedSprite2D

func _ready():
	TutorialManager.set_tutorial_sprite(self)

func _process(_delta: float):
	if sprite != null:
		visible = true
		sprite_frames = sprite.sprite_frames
		animation = sprite.animation
		offset = sprite.offset
		set_position(sprite.get_global_transform_with_canvas().get_origin()) # Find better way than hardcoding later
		set_scale(sprite.get_global_transform_with_canvas().get_scale())
	else:
		sprite_frames = null
		visible = false