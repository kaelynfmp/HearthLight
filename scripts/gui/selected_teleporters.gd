extends Control

signal connector_enabled
signal connector_disabled

@export var selected_teleporter_scene:PackedScene
@export var cable_scene:PackedScene
@export var teleporter:Gadget
@export var output_colour:Color
@export var input_colour:Color
var connector:bool

func _ready() -> void:
	GameManager.teleporter_list_changed.connect(rebuild_teleporters)
	GameManager.right_click_pressed.connect(cancel_connector)
	GameManager.inventory_open_state_changed.connect(rebuild_teleporters)
	GameManager.gadget_changed.connect(rebuild_teleporters)
	GameManager.gadget_changed.connect(cancel_connector)
	GameManager.character.camera_moved.connect(rebuild_teleporters)

func _process(_delta: float) -> void:
	if GameManager.gadget == null or GameManager.gadget.gadget_stats != teleporter:
		return
		
func rebuild_teleporters() -> void:
	for node in get_children():
		if node.get_name() != "Cables":
			remove_child(node)
			node.queue_free()
		else:
			for node2 in node.get_children():
				node.remove_child(node2)
				node2.queue_free()
	
	if GameManager.gadget == null: return
	for _teleporter:InWorldGadget in GameManager.teleporters:
		if _teleporter == GameManager.gadget: continue
		var teleporter_scene:AnimatedSprite2D = selected_teleporter_scene.instantiate()
		teleporter_scene.teleporter = _teleporter
		connector_enabled.connect(teleporter_scene._connector_enabled)
		connector_disabled.connect(teleporter_scene._connector_disabled)
		add_child(teleporter_scene)
		if _teleporter in GameManager.gadget.target_list:
			# Visualize connection
			create_cable(get_origin(GameManager.gadget), get_origin(_teleporter), output_colour)
		elif GameManager.gadget in _teleporter.target_list:
			# Visualize connection
			create_cable(get_origin(_teleporter), get_origin(GameManager.gadget), input_colour)
			
	if connector:
		_on_add_teleport_pressed()
			
func get_origin(_teleporter:InWorldGadget) -> Vector2:
	return _teleporter.find_child("Sprite").get_global_transform_with_canvas().get_origin() - Vector2(0, 18)
	
func create_cable(origin_position:Vector2, end_position:Vector2, colour:Color, locked_to_mouse=false, _name=""):
	var cable:Cable = cable_scene.instantiate()
	cable.locked_to_mouse = locked_to_mouse
	cable.origin_position = origin_position
	cable.end_position = end_position
	cable.colour = colour
	cable.z_index += 2
	if _name != "":
		cable.set_name(_name)
	$Cables.add_child(cable)

func _on_add_teleport_pressed() -> void:
	if GameManager.gadget == null: return
	create_connector()
	connector_enabled.emit()
	connector = true

func cancel_connector():
	connector_disabled.emit()
	for node in $Cables.get_children():
		if node.get_name() == "CursorConnector":
			$Cables.remove_child(node)
			node.queue_free()
			break
	connector = false
	
func create_connector() -> void:
	create_cable(get_origin(GameManager.gadget), Vector2(0, 0), output_colour, true, "CursorConnector")
