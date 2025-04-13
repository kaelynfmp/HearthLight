extends AnimatedSprite2D

var teleporter:InWorldGadget
var connector_state:bool
@export var add_shader_texture:Texture
@export var remove_shader_texture:Texture
@export var empty_texture:Texture

func _ready() -> void:
	$ClickableControl/ClickableArea.mouse_entered.connect(_on_clickable_area_mouse_entered)
	$ClickableControl/ClickableArea.mouse_exited.connect(_on_clickable_area_mouse_exited)

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
	$ClickableControl.visible = connector_state
	
func _connector_enabled():
	connector_state = true
	
func _connector_disabled():
	connector_state = false
	
func _on_clickable_area_mouse_entered() -> void:
	get_material().set_shader_parameter("scrollingTexture", add_shader_texture)

func _on_clickable_area_mouse_exited() -> void:
	get_material().set_shader_parameter("scrollingTexture", empty_texture)	
