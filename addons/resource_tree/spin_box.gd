@tool
extends SpinBox

@export var slot:Slot

# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	var line_edit:LineEdit = get_line_edit()
	line_edit.context_menu_enabled = false
	line_edit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	line_edit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	line_edit.add_theme_stylebox_override("read_only", StyleBoxEmpty.new())

func _process(_delta: float):
	visible = slot.item != null

func connect_slot():
	slot.changed.connect(update_value)

func _on_value_changed(value:float) -> void:
	slot.quantity = int(value)
	set_value(slot.quantity)
	
func update_value():
	set_value(slot.quantity)