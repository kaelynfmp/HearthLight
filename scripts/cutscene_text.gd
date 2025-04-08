extends RichTextLabel

func _process(_delta: float):
	text = GameManager.current_cutscene.text[GameManager.current_cutscene.step]
