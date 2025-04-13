extends AnimatedSprite2D

@onready var marker: Node2D = get_node("/root/Room/Tilemap/TileLayers/Marker")
@onready var base_layer: Node2D = get_node("/root/Room/Tilemap/TileLayers/Base")

func _process(_delta: float) -> void:
	if GameManager.gadget != null:
		visible = true
		var sprite:AnimatedSprite2D = GameManager.gadget.find_child("Sprite")
		sprite_frames = sprite.sprite_frames
		animation = sprite.animation
		offset = sprite.offset
		set_position(sprite.get_global_transform_with_canvas().get_origin()) # Find better way than hardcoding later
		set_scale(GameManager.gadget.get_global_transform_with_canvas().get_scale() * sprite.get_scale())
		if GameManager.gadget.gadget_stats.name in ["Conveyor Belt", "Teleporter"]:
			$Control.visible = true
		else:
			$Control.visible = false
			
		if GameManager.gadget.gadget_stats.name == "Generator":
			marker.visible = true
			marker.is_generator = true
			marker.is_uni_generator = false
			marker.position = base_layer.map_to_local(GameManager.gadget.cell_pos)
		elif GameManager.gadget.gadget_stats.name == "Universal Generator":
			marker.is_generator = false
			marker.is_uni_generator = true
			marker.visible = true
			marker.position = Vector2i(0, 0)
			
	else:
		sprite_frames = null
		visible = false
		$Control.visible = false


func _on_rotate_left_pressed() -> void:
	GameManager.gadget.direction = (GameManager.gadget.direction - 1 + 4) % 4


func _on_rotate_right_pressed() -> void:
	GameManager.gadget.direction = (GameManager.gadget.direction + 1) % 4
