extends AudioStreamPlayer2D


func _on_ready() -> void:
	AudioManager.set_good_ending_audio(self) # Replace with function body.


func _on_finished() -> void:
	play() # Replace with function body.
