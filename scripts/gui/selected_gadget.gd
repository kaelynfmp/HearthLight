extends AnimatedSprite2D

var prev_gadget:InWorldGadget
var teleporter_selected:bool

func _ready() -> void:
	GameManager.right_click_pressed.connect(cancel_connector)

func _process(_delta: float) -> void:
	if GameManager.gadget != null:
		if GameManager.gadget != prev_gadget:
			prev_gadget = GameManager.gadget
			teleporter_selected = false
		visible = true
		var sprite:AnimatedSprite2D = GameManager.gadget.find_child("Sprite")
		sprite_frames = sprite.sprite_frames
		animation = sprite.animation
		offset = sprite.offset
		set_position(sprite.get_global_transform_with_canvas().get_origin()) # Find better way than hardcoding later
		set_scale(GameManager.gadget.get_global_transform_with_canvas().get_scale() * sprite.get_scale())
		if GameManager.gadget.gadget_stats.name in ["Conveyor Belt", "Teleporter"]:
			$RotationControl.visible = true
		else:
			$RotationControl.visible = false
		if GameManager.gadget.gadget_stats.name == "Teleporter" and not teleporter_selected:
			$TeleportControl.visible = true
		else:
			$TeleportControl.visible = false
			
	else:
		sprite_frames = null
		visible = false
		$RotationControl.visible = false
		$TeleportControl.visible = false
		teleporter_selected = false
		
func _on_rotate_left_pressed() -> void:
	GameManager.gadget.direction = (GameManager.gadget.direction + 1) % 4
	
func _on_rotate_right_pressed() -> void:
	GameManager.gadget.direction = (GameManager.gadget.direction - 1 + 4) % 4

func _on_add_teleport_pressed() -> void:
	teleporter_selected = true
	
func cancel_connector():
	teleporter_selected = false
