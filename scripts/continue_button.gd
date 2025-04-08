extends Button

@export var button_sound:AudioManager.BUTTON

func _process(_delta: float):
	if GameManager.current_cutscene.step < GameManager.current_cutscene.text.size() - 1:
		text = "Continue"
	else:
		text = GameManager.current_cutscene.final_button_text
		
func _pressed():
	if not GameManager.current_cutscene.next_step():
		GameManager.conclude_cutscene()
	
