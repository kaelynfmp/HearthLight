extends Node2D

@onready var slot: Slot = preload("res://resources/character/cursorslot.tres")
@onready var slot_panel:PanelContainer = $Slot

func _ready() -> void:
	GameManager.set_cursor(self)
	slot_panel.set_slot(slot)

func _process(_delta: float) -> void:
	position = get_global_mouse_position()
	
func update_slot():
	slot_panel.update()