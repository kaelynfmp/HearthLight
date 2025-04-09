extends Node2D

@onready var slot: Slot = preload("res://resources/character/cursorslot.tres")
@onready var slot_panel:PanelContainer = $Slot
var item_texture_rect: TextureRect
enum Direction {SE, SW, NW, NE}

func _ready() -> void:
	GameManager.set_cursor(self)
	slot_panel.set_slot(slot)
	item_texture_rect = find_child("Item")
	GameManager.gadget_rotated.connect(flip_texture)
	
func flip_texture(direction: int) -> void:
	var gadget = GameManager.get_gadget_from_cursor()
	if slot.item != null and slot.item.name in ["Conveyor Belt", "Teleporter"]:
		match (direction):
			Direction.SE:
				item_texture_rect.set_texture(gadget.sprite_frames.get_frame_texture("se", 0))
			Direction.SW:
				item_texture_rect.set_texture(gadget.sprite_frames.get_frame_texture("sw", 0))
			Direction.NE:
				item_texture_rect.set_texture(gadget.sprite_frames.get_frame_texture("ne", 0))
			Direction.NW:
				item_texture_rect.set_texture(gadget.sprite_frames.get_frame_texture("nw", 0))

func _process(_delta: float) -> void:
	position = get_global_mouse_position()
	var gadget = GameManager.get_gadget_from_cursor()
	if gadget != null and slot.item != null and slot.item.name in ["Conveyor Belt", "Teleporter"]:
		var direction = gadget.direction
		flip_texture(direction)
		
	
func update_slot():
	slot_panel.update()
