extends Panel
@onready var close_button = $CloseSellPanel
@onready var sell_button = $SellButton
@onready var inventory: Inventory = preload("res://resources/character/inventory.tres")
@onready var input_slot = $InputSlot
var slot_scene = preload("res://scenes/inventory/input_slot.tscn")
var duplicate_slot

func _ready() -> void:
	close_button.pressed.connect(on_close_button_pressed)
	sell_button.pressed.connect(on_sell_button_pressed)
	duplicate_slot = input_slot.duplicate()

func _process(delta: float) -> void:
	if visible and !GameManager.inventory and GameManager.computer_visible:
		GameManager.change_inventory()
	if GameManager.computer_tab_manager.current_tab != 1 and visible:
		on_close_button_pressed()

	
func on_close_button_pressed():
	visible = false
	if GameManager.inventory:
		GameManager.change_inventory()
	#todo: send item back to inventory

func on_sell_button_pressed() -> void:
	if input_slot and input_slot.slot.item:
		print("sold")
		# replace slot aka poof magic disappear item if its in there
		var parent = input_slot.get_parent()
		var new_slot = duplicate_slot
		duplicate_slot = new_slot.duplicate()
		parent.remove_child(input_slot)
		input_slot.queue_free()
		parent.add_child(new_slot)
		input_slot = new_slot
