extends Control
@export var currency_label: Label
@export var exit_button: Button
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	exit_button.pressed.connect(func(): _close_computer())
	GameManager.computer_visibility_changed.connect(change_computer_visibility)
	GameManager.computer_tab_manager = find_child("Sites")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	currency_label.text = "       "+str(GameManager.currency)
	GameManager.in_computer = GameManager.computer_visible

func _close_computer():
	GameManager.change_computer_visibility()
	
func change_computer_visibility():
	if GameManager.computer_visible:
		show()
	else:
		hide()

		
