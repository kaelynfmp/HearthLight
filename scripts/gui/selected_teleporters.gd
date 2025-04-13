extends Control

signal connector_enabled
signal connector_disabled

@export var selected_teleporter_scene:PackedScene
@export var cable_scene:PackedScene
@export var teleporter:Gadget
@export var output_colour:Color
@export var input_colour:Color

func _ready() -> void:
	GameManager.teleporter_list_changed.connect(rebuild_teleporters)
	GameManager.right_click_pressed.connect(cancel_connector)
	GameManager.inventory_open_state_changed.connect(cancel_connector)
	GameManager.gadget_changed.connect(rebuild_teleporters)

func _process(_delta: float) -> void:
	if GameManager.gadget == null or GameManager.gadget.gadget_stats != teleporter:
		return
		
func rebuild_teleporters():
	for node in get_children():
		if node.get_name() != "Cables":
			remove_child(node)
			node.queue_free()
		else:
			for node2 in node.get_children():
				node.remove_child(node2)
				node2.queue_free()
	
	for _teleporter:InWorldGadget in GameManager.teleporters:
		if _teleporter == GameManager.gadget: continue
		var teleporter_scene:AnimatedSprite2D = selected_teleporter_scene.instantiate()
		teleporter_scene.teleporter = _teleporter
		connector_enabled.connect(teleporter_scene._connector_enabled)
		connector_disabled.connect(teleporter_scene._connector_disabled)
		add_child(teleporter_scene)
	
func _on_add_teleport_pressed() -> void:
	if GameManager.gadget == null: return
	var cable:Cable = cable_scene.instantiate()
	cable.locked_to_mouse = true
	cable.origin_position = GameManager.gadget.find_child("Sprite").get_global_transform_with_canvas().get_origin() - Vector2(0, 18)
	cable.colour = output_colour
	cable.z_index += 2
	cable.set_name("CursorConnector")
	$Cables.add_child(cable)
	connector_enabled.emit()

func cancel_connector():
	connector_disabled.emit()
	for node in $Cables.get_children():
		if node.get_name() == "CursorConnector":
			$Cables.remove_child(node)
			node.queue_free()
			break
