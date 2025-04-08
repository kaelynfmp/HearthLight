extends Control

func _ready():
	visible = true

func _process(_delta: float) -> void:
	if GameManager.cutscene_displayed:
		visible = true
		if modulate.a < 1:
			modulate.a += 0.005
		if modulate.a >= 1:
			pass
	else:
		if modulate.a > 0:
			modulate.a -= 0.005  # Gradually fade out
		else:
			visible = false  # Hide when fully faded out
	
	
