extends TabContainer

func _on_tab_clicked(_tab:int) -> void:
	AudioManager.play_button_sound(AudioManager.BUTTON.CLICK)
