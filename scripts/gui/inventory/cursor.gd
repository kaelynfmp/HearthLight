extends Node2D

@onready var slot: Slot = preload("res://resources/character/cursorslot.tres")
@onready var slot_panel:PanelContainer = $Slot
var item_texture_rect: TextureRect

func _ready() -> void:
	GameManager.set_cursor(self)
	slot_panel.set_slot(slot)
	item_texture_rect = find_child("Item")
	item_texture_rect.flip_h = false
	item_texture_rect.flip_v = false
	GameManager.gadget_rotated.connect(flip_texture)
	
func flip_texture(direction: int) -> void:
	if slot.item != null and slot.item.name == "Conveyor Belt":
		item_texture_rect.flip_h = false
		item_texture_rect.flip_v = false
		if direction == 1 or direction == 2:
			item_texture_rect.flip_h = true
		if direction == 2 or direction == 3:
			item_texture_rect.flip_v = true

func _process(_delta: float) -> void:
	position = get_global_mouse_position()
	var gadget = GameManager.get_gadget_from_cursor()
	if gadget != null and slot.item != null and slot.item.name == "Conveyor Belt":
		var direction = gadget.direction
		item_texture_rect.flip_h = false
		item_texture_rect.flip_v = false
		if direction == 1 or direction == 2:
			item_texture_rect.flip_h = true
		if direction == 2 or direction == 3:
			item_texture_rect.flip_v = true
	else:
		item_texture_rect.flip_h = false
		item_texture_rect.flip_v = false
	
func update_slot():
	slot_panel.update()
