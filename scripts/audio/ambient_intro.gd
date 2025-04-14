extends AudioStreamPlayer2D

var loop: bool = true

func _on_finished() -> void:
	if loop:
		play() # Replace with function body.


func _on_ready() -> void:
	AudioManager.set_intro_ambient_audio(self) # Replace with function body.
	
