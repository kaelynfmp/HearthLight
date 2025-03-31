extends Control
func _ready():
	visible = true
	modulate.a = 0
func _process(delta: float) -> void:
	if GameManager.sleeping:
		visible = true
		if modulate.a < 0.7:
			modulate.a += 0.005
		if modulate.a >= 0.7:
			pass
	else:
		if modulate.a > 0:
			modulate.a -= 0.05  # Gradually fade out
		else:
			visible = false  # Hide when fully faded out
	
	
