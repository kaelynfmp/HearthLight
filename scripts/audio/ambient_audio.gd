extends AudioStreamPlayer2D

var loop: bool = true

func _ready() -> void:
	AudioManager.set_ambient_audio(self)

func _on_finished() -> void:
	if loop:
		play()
