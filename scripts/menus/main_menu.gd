extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/room.tscn")


func _on_credit_pressed() -> void:
	$Label.visible = false
	$MainMenuButtonContainers.visible = false
	$CreditContainers.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	$Label.visible = true
	$MainMenuButtonContainers.visible = true
	$CreditContainers.visible = false # Replace with function body.
