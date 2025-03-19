extends Sprite2D

func _process(delta: float) -> void:
	if GameManager.gadget != null:
		visible = true
		var sprite = GameManager.gadget.find_child("Sprite")
		texture = sprite.texture
		offset = sprite.offset
		flip_h = false
		flip_v = false
		flip_h = sprite.flip_h
		flip_v = sprite.flip_v
		set_position(sprite.get_global_transform_with_canvas().get_origin()) # Find better way than hardcoding later
		set_scale(GameManager.gadget.get_global_transform_with_canvas().get_scale() * sprite.get_scale())
		if GameManager.gadget.gadget_stats.name == "Conveyor Belt":
			$Control.visible = true
			
	else:
		texture = null
		visible = false
		$Control.visible = false


func _on_rotate_left_pressed() -> void:
	GameManager.gadget.direction = (GameManager.gadget.direction + 1) % 4


func _on_rotate_right_pressed() -> void:
	GameManager.gadget.direction = (GameManager.gadget.direction - 1 + 4) % 4
