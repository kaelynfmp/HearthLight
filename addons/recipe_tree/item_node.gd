@tool
extends GraphNode

@onready var item_node:ItemEditorNode
@onready var close_button:PackedScene

signal moved(to:Vector2, item_node:ItemEditorNode)
signal kill

func _ready() -> void:
	close_button = load("res://addons/recipe_tree/close_button.tscn")
	var close_node:TextureButton = close_button.instantiate()
	get_titlebar_hbox().add_child(close_node)
	close_node.pressed.connect(close_pressed)

func _process(_delta: float) -> void:
	if item_node == null: return
	if item_node.item == null: return
	if $ItemImage.texture != item_node.item.texture:
		$ItemImage.texture = item_node.item.texture
	if title != item_node.item.name:
		title = item_node.item.name

func close_pressed():
	kill.emit(self)
	
func _on_dragged(from:Vector2, to:Vector2) -> void:
	moved.emit(to, item_node)