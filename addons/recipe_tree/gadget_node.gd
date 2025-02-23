@tool
extends GraphNode

@onready var gadget_node:GadgetEditorNode
signal moved(to:Vector2, gadget_node:GadgetEditorNode)

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if gadget_node == null: return
	if gadget_node.gadget == null: return
	if $GadgetImage.texture != gadget_node.gadget.texture:
		$GadgetImage.texture = gadget_node.gadget.texture
	if title != gadget_node.gadget.name:
		title = gadget_node.gadget.name
	
func _on_dragged(from:Vector2, to:Vector2) -> void:
	moved.emit(to, gadget_node)