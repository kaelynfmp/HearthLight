extends Control

@export var animation_player:AnimationPlayer

func splash_finish():
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")

func _on_animation_player_animation_finished(_anim_name:StringName) -> void:
	splash_finish()
