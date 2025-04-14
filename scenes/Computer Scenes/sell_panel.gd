extends Panel
@onready var close_button = $CloseSellPanel
@onready var sell_button = $SellButton
@onready var inventory: Inventory = preload("res://resources/character/inventory.tres")
@onready var input_slot = $InputSlot
@onready var cost_label = $Cost
var base_price_ratio = 0.10
#var special_price_ratio = 0.01
var price: int = 0
var slot_scene = preload("res://scenes/inventory/input_slot.tscn")
var duplicate_slot
var slot_bg
func _ready() -> void:
	slot_bg = input_slot.find_child("InputBG")
	slot_bg.modulate.a = 0
	close_button.pressed.connect(on_close_button_pressed)
	sell_button.pressed.connect(on_sell_button_pressed)
	duplicate_slot = input_slot.duplicate()
	GameManager.sell_slot = input_slot.slot

func _process(delta: float) -> void:
	if input_slot and input_slot.slot and input_slot.slot.item:
		sell_button.disabled = false
		var slot = input_slot.slot
		var item = slot.item
		price = ceil((item.price * base_price_ratio) * slot.quantity)
		cost_label.text = "+$"+str(price)
		input_slot.update()
		
	if input_slot and input_slot.slot and (!input_slot.slot.item or input_slot.slot.quantity == 0):
		sell_button.disabled = true
		price = 0
		cost_label.text = "$"+str(price)
		input_slot.update()
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
	if input_slot and input_slot.slot and input_slot.slot.item:
		print("sold")
		# add currency
		GameManager.add_currency(price)
		AudioManager.play_button_sound(AudioManager.BUTTON.BUY)
		
		input_slot.slot.item = null
		input_slot.slot.quantity = 0
		
