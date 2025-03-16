extends Sprite2D

func _process(delta: float) -> void:
	if GameManager.gadget != null:
		visible = true
		var sprite = GameManager.gadget.find_child("Sprite")
		texture = sprite.texture
		set_position(sprite.get_global_transform_with_canvas().get_origin()) # Find better way than hardcoding later
		set_scale(GameManager.gadget.get_global_transform_with_canvas().get_scale() * sprite.get_scale())
		
	else:
		texture = null
		visible = false
