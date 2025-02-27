extends Node
@export var currency_label: Label
@export var exit_button: Button
var parent_node : Node = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	exit_button.pressed.connect(func(): _close_computer())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	currency_label.text = "      "+str(GameManager.currency)

func _close_computer():
	if parent_node:
		parent_node.toggle_computer()
