@tool
extends GraphNode

@onready var item_node:ItemEditorNode
signal moved(to:Vector2, item_node:ItemEditorNode)

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if item_node == null: return
	if item_node.item == null: return
	if $ItemImage.texture != item_node.item.texture:
		$ItemImage.texture = item_node.item.texture
	if title != item_node.item.name:
		title = item_node.item.name

func _on_dragged(from:Vector2, to:Vector2) -> void:
	moved.emit(to, item_node)