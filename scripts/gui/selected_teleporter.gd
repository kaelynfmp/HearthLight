extends AnimatedSprite2D

var teleporter:InWorldGadget
var connector_state:bool
var existing_connection:bool
@export var add_shader_texture:Texture
@export var remove_shader_texture:Texture
@export var empty_texture:Texture

func _ready() -> void:
	$ClickableControl/ClickableArea.mouse_entered.connect(_on_clickable_area_mouse_entered)
	$ClickableControl/ClickableArea.mouse_exited.connect(_on_clickable_area_mouse_exited)
	$ClickableControl/ClickableArea.gui_input.connect(_on_clickable_area_gui_input)
	if GameManager.gadget != null and teleporter in GameManager.gadget.target_list:
		existing_connection = true

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
	get_material().set_shader_parameter("scrollingTexture", add_shader_texture if not existing_connection else remove_shader_texture)

func _on_clickable_area_mouse_exited() -> void:
	get_material().set_shader_parameter("scrollingTexture", empty_texture)	

func _on_clickable_area_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		teleporter.initial_click = true
		if existing_connection:
			GameManager.gadget.remove_teleporter(teleporter)
		else:
			GameManager.gadget.add_teleporter(teleporter)
