@tool
extends GraphNode

@onready var gadget_node:GadgetEditorNode
@onready var close_button:PackedScene

signal moved(to:Vector2, gadget_node:GadgetEditorNode)
signal kill(node:GraphNode)

func _ready() -> void:
	close_button = load("res://addons/resource_tree/close_button.tscn")
	var close_node:TextureButton = close_button.instantiate()
	get_titlebar_hbox().add_child(close_node)
	close_node.pressed.connect(close_pressed)

func _process(_delta: float) -> void:
	if !get_parent_control().visible: return
	if gadget_node == null: return
	if gadget_node.gadget == null:
		$GadgetImage.texture = null
		return
	if $GadgetImage.texture != gadget_node.gadget.item.texture:
		$GadgetImage.set_texture(gadget_node.gadget.item.texture)
	if title != gadget_node.gadget.name:
		title = gadget_node.gadget.name
	
func close_pressed():
	kill.emit(self)
	
func _on_dragged(from:Vector2, to:Vector2) -> void:
	moved.emit(to, gadget_node)

func _on_node_selected() -> void:
	EditorInterface.edit_resource(gadget_node.gadget)