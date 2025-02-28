extends Control

signal is_paused

var is_displayed = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.pause_changed.connect(_display)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	visible = is_displayed
	if visible:
		get_tree().paused = true
	else:
		get_tree().paused = false
	
func _display() -> void:
	is_displayed = !is_displayed


func _on_to_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_resume_pressed() -> void:
	is_displayed = false
	GameManager.pause = false
