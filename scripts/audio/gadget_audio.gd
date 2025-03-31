extends AudioStreamPlayer2D

func _ready() -> void:
	AudioManager.set_gadget_audio(self)

func _on_finished() -> void:
	play()
