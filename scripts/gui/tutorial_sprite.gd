extends Sprite2D

var sprite:Sprite2D

func _ready():
	TutorialManager.set_tutorial_sprite(self)

func _process(_delta: float):
	if sprite != null:
		visible = true
		texture = sprite.texture
		offset = sprite.offset
		flip_h = false
		flip_v = false
		flip_h = sprite.flip_h
		flip_v = sprite.flip_v
		set_position(sprite.get_global_transform_with_canvas().get_origin()) # Find better way than hardcoding later
		set_scale(sprite.get_global_transform_with_canvas().get_scale())
	else:
		texture = null
		visible = false