extends ColorRect

func _ready() -> void:
	GameManager.inventory_open_state_changed.connect(on_inventory_open_state_changed)

func on_inventory_open_state_changed():
	visible = !visible
