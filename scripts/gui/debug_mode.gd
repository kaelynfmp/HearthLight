extends RichTextLabel

func _ready() -> void:
	GameManager.debug_mode_change.connect(func(): visible = GameManager.is_debugging)
