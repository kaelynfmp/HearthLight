extends Control

@onready var inventory: Inventory = preload("res://resources/character/inventory.tres")
@onready var open_audio:AudioStreamPlayer2D = get_node("OpenAudio")
@onready var close_audio:AudioStreamPlayer2D = get_node("CloseAudio")

var is_open:bool

func _ready() -> void:
	inventory.changed.connect(update_slots)
	update_slots()
	GameManager.inventory_open_state_changed.connect(on_inventory_open_state_changed)
	GameManager.take_cursor.connect(on_take_cursor)
	
func update_slots():
	var slots = $Background/Slots.get_children()
	for i in range(min(inventory.slots.size(), slots.size())):
		slots[i].set_slot(inventory.slots[i])
	
func on_inventory_open_state_changed():
	is_open = !is_open
	if is_open:
		close_audio.play()
		GameManager.inventories.append(inventory)
	else:
		open_audio.play()

func on_take_cursor(slot:Slot):
	inventory.insert(slot.item, slot.quantity)
