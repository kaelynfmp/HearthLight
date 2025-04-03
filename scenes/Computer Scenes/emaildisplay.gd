extends Button

var email: Email

@export var sender_label: RichTextLabel 
@export var subject_label: RichTextLabel
@export var sender_dropdown: RichTextLabel
@export var subject_dropdown: RichTextLabel
@export var blurb_label: RichTextLabel
@export var content: RichTextLabel
@export var expand_panel: Panel  # expanded email content
@export var fulfill_button: Button
@export var button_sprite: Sprite2D
@export var clock: TextureRect
@export var bg: TextureRect
@export var bottom_bar: TextureRect

@export var button_sound: AudioManager.BUTTON

var prev_read:bool = false

func _process(_delta: float) -> void:
	if email.is_read and !prev_read and not email.tutorial:
		prev_read = true
		button_sprite.texture = preload("res://resources/sprites/emails/emailPreview.png")
	if fulfill_button.visible and GameManager.computer_visible and email != null and email.attached_order != null:
		fulfill_button.disabled = !GameManager.player_inventory_has(email.attached_order.required_items, email.attached_order.required_quantities)

func set_email(new_email: Email):
	email = new_email
	sender_label.finished.connect(_finished.bind(email.sender, sender_label))
	subject_label.finished.connect(_finished.bind(email.subject, subject_label))
	blurb_label.finished.connect(_finished.bind(email.contents.split("\n")[0], blurb_label))
	
	sender_dropdown.finished.connect(_finished.bind(email.sender, sender_dropdown))
	subject_dropdown.finished.connect(_finished.bind(email.subject, subject_dropdown))
	
	content.text = email.contents
	expand_panel.visible = false
	if not email.tutorial and email.attached_order != null:
		bg.texture = preload("res://resources/sprites/emails/emailDropdownTimed.png")
		bottom_bar.texture = preload("res://resources/sprites/emails/emailBottomBarTimed.png")
		clock.set_visible(true)
	
func _finished(_text:String, label:RichTextLabel):
	if !label.initialized:
		label.initialized = true
		Utility.call_deferred("set_truncated_text", _text, label) # Called deferred to ensure font size is correct
		
	
