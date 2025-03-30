extends Control
@onready var timer = Timer.new()
func _ready():
	visible = true
	modulate.a = 0
	add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
func _process(delta: float) -> void:
	if GameManager.sleeping:
		visible = true
		modulate.a = 0.2
	else:
		visible = false
		modulate.a = 0
