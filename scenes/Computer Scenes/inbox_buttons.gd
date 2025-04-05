extends Button

@export var button_sound:AudioManager.BUTTON
@export var sprite:Sprite2D
@export var notification:Panel
var main_texture:Texture
var category:String
var prev_empty:bool = false
var prev_has_unreads:bool = false

func _ready() -> void:
	sprite.texture = main_texture

func _physics_process(_delta: float) -> void:
	var valid_emails_in_category = GameManager.categorized_emails[category].filter(func(email: Email): return email.check_valid())
	if not prev_empty and valid_emails_in_category.is_empty():
		prev_empty = true
		disabled = true
		sprite.modulate = Color(0.733, 0.733, 0.733, 0.533)
	elif prev_empty and not valid_emails_in_category.is_empty():
		prev_empty = false
		disabled = false
		sprite.modulate = Color(1, 1, 1, 1)
	if not disabled:
		var has_unreads = GameManager.categorized_emails[category].any(func(email: Email): return email.check_valid() and not email.is_read)
		if prev_has_unreads != has_unreads:
			prev_has_unreads = has_unreads
			if has_unreads:
				notification.set_visible(true)
			else:
				notification.set_visible(false)