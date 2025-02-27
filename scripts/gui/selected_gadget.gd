extends TextureRect



func _process(delta: float) -> void:
	if GameManager.gadget != null:
		visible = true
		texture = GameManager.gadget.find_child("Sprite").texture
		set_position(GameManager.gadget.find_child("Sprite").get_global_transform_with_canvas().get_origin() - Vector2(58, 97)) # Find better way than hardcoding later
		set_scale(GameManager.gadget.get_global_transform_with_canvas().get_scale() * GameManager.gadget.find_child("Sprite").get_scale())
	else:
		texture = null
		visible = false
