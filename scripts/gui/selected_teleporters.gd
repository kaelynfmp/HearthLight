extends Control

@export var selected_teleporter_scene:PackedScene
@export var teleporter:Gadget

func _ready() -> void:
	GameManager.teleporter_list_changed.connect(_teleporter_list_changed)

func _process(_delta: float) -> void:
	if GameManager.gadget == null or GameManager.gadget.gadget_stats != teleporter:
		return
	
func _teleporter_list_changed():
	for node in get_children():
		remove_child(node)
		node.queue_free()
	
	for _teleporter:InWorldGadget in GameManager.teleporters:
		var teleporter_scene:AnimatedSprite2D = selected_teleporter_scene.instantiate()
		teleporter_scene.teleporter = _teleporter
		add_child(teleporter_scene)