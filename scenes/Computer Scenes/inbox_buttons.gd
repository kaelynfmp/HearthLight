extends Button

@export var button_sound:AudioManager.BUTTON
@export var sprite:Sprite2D
var main_texture:Texture
var category:String
var prev_empty:bool = false

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