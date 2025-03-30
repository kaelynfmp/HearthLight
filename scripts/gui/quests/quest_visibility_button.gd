extends TextureButton

@export var close:bool

func _process(_delta: float) -> void:
	visible = GameManager.quest_list_visible if close else !GameManager.quest_list_visible

func _on_pressed() -> void:
	GameManager.quest_list_visible = !GameManager.quest_list_visible
