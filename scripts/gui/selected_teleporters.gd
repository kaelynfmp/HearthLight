extends Control

@export var selected_teleporter_scene:PackedScene
@export var cable_scene:PackedScene
@export var teleporter:Gadget

func _ready() -> void:
	GameManager.teleporter_list_changed.connect(_teleporter_list_changed)
	GameManager.right_click_pressed.connect(cancel_connector)

func _process(_delta: float) -> void:
	if GameManager.gadget == null or GameManager.gadget.gadget_stats != teleporter:
		return
	
func _teleporter_list_changed():
	for node in get_children():
		if node.get_name() != "Cables":
			remove_child(node)
			node.queue_free()
		else:
			for node2 in node.get_children():
				node.remove_child(node)
				node2.queue_free()
	
	for _teleporter:InWorldGadget in GameManager.teleporters:
		var teleporter_scene:AnimatedSprite2D = selected_teleporter_scene.instantiate()
		teleporter_scene.teleporter = _teleporter
		add_child(teleporter_scene)

func _on_add_teleport_pressed() -> void:
	if GameManager.gadget == null: return
	var cable:Cable = cable_scene.instantiate()
	cable.locked_to_mouse = true
	cable.origin_position = GameManager.gadget.find_child("Sprite").get_global_transform_with_canvas().get_origin() - Vector2(0, 18)
	cable.z_index += 2
	cable.set_name("CursorConnector")
	$Cables.add_child(cable)

func cancel_connector():
	for node in $Cables.get_children():
		if node.get_name() == "CursorConnector":
			$Cables.remove_child(node)
			node.queue_free()
			break
