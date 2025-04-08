extends Label

func _process(_delta: float) -> void:
	text = "$" + str(GameManager.debt)
	if GameManager.is_debugging:
		text = "$NONE!"
