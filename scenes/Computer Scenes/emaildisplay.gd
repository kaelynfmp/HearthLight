extends Button

var email: Email

@export var sender_label: RichTextLabel 
@export var email_label: RichTextLabel
@export var subject_label: RichTextLabel
@export var sender_dropdown: RichTextLabel
@export var email_dropdown: RichTextLabel
@export var subject_dropdown: RichTextLabel
@export var blurb_label: RichTextLabel
@export var content: RichTextLabel
@export var expand_panel: Panel  # expanded email content
@export var fulfill_button: Button
@export var button_sprite: Sprite2D
@export var clock: TextureRect
@export var bg: TextureRect
@export var top_bar: TextureRect
@export var bottom_bar: TextureRect

@export var button_sprite_read:Texture
@export var top_bar_read:Texture

@export var button_sprite_timed:Texture
@export var top_bar_timed:Texture
@export var bg_timed:Texture
@export var bottom_bar_timed:Texture

@export var unread_button_sprite:Texture
@export var unread_top_bar:Texture

@export var button_sound: AudioManager.BUTTON


var prev_read:bool = false

func _process(_delta: float) -> void:
	if email.is_read and !prev_read and ((not email.tutorial and not email.bankruptcy) or email.archived):
		prev_read = true
		if not email.tutorial and not email.bankruptcy and email.attached_order != null:
			button_sprite.texture = button_sprite_timed
			top_bar.texture = top_bar_timed
		else:
			button_sprite.texture = button_sprite_read
			top_bar.texture = top_bar_read
	if fulfill_button.visible and GameManager.computer_visible and email != null and email.attached_order != null:
		fulfill_button.disabled = not GameManager.is_debugging and !GameManager.player_inventory_has(email.attached_order.required_items, email.attached_order.required_quantities)

func set_email(new_email: Email):
	email = new_email
	sender_label.finished.connect(_finished.bind(email.sender, sender_label))
	email_label.finished.connect(_finished.bind(email.email, email_label))
	subject_label.finished.connect(_finished.bind(email.subject, subject_label))
	blurb_label.finished.connect(_finished.bind(email.contents.split("\n")[0], blurb_label))
	
	sender_dropdown.finished.connect(_finished.bind(email.sender, sender_dropdown))
	email_dropdown.finished.connect(_finished.bind(email.email, email_dropdown))
	subject_dropdown.finished.connect(_finished.bind(email.subject, subject_dropdown))
	
	content.text = email.contents
	expand_panel.visible = false
	button_sprite.texture = unread_button_sprite
	top_bar.texture = unread_top_bar
	
	if not email.tutorial and not email.bankruptcy and email.attached_order != null:
		bg.texture = bg_timed
		bottom_bar.texture = bottom_bar_timed
		clock.set_visible(true)
	
func _finished(_text:String, label):
	if !label.initialized and label != null:
		label.initialized = true
		Utility.call_deferred("set_truncated_text", _text, label) # Called deferred to ensure font size is correct
		
	
