extends Node
var item: Item
@export var item_name: Label
@export var item_desc: RichTextLabel
@export var item_picture: TextureRect
@onready var inventory: Inventory = preload("res://resources/character/inventory.tres")

# quantity select
@export var min_value: int = 1
@export var max_value: int = 99
var cost_per_item: int = 10 
@export var cost_label: Label
var quantity: int = 1  # Default quantity

@export var number_label: SpinBox
@export var minus_button: Button
@export var plus_button: Button

@export var buy_button: Button
@export var decline_button: Button
var total_cost: int

func _ready():
	update_label()
	minus_button.pressed.connect(_decrease)
	plus_button.pressed.connect(_increase)
	buy_button.pressed.connect(_buy)
	decline_button.pressed.connect(_close)
	number_label.min_value = min_value
	number_label.max_value = max_value
	number_label.value_changed.connect(_changed)

func _process(_delta: float) -> void:
	if GameManager.in_computer == false:
		queue_free()

func _close():
	queue_free()

func _buy():
	if GameManager.subtract_currency(total_cost) == true: # successful purchase
		# ADD ITEM TO INVENTORY
		# insert(item: Item, amount=1)
		#var player = get_tree().get_first_node_in_group("character")  # Find the player
		if inventory.can_insert(item, quantity) == 0:
			# Success state
			AudioManager.play_button_sound(AudioManager.BUTTON.BUY)
			inventory.insert(item, quantity)
			queue_free()
			return
		else:
			# TODO: proper error handling
			GameManager.add_currency(total_cost)
			print("Error inserting bought item into inventory")
		
	else:
		# Fail state
		AudioManager.play_button_sound(AudioManager.BUTTON.NO_MONEY)
		# maybe show insufficient funds in future
		# show buy button as unavailable if currency not enough? future goal


func set_item_buy(new_item: Item):
	item = new_item
	item_name.text = item.name
	item_desc.text = item.description
	item_picture.texture = item.texture
	cost_per_item = item.price
	total_cost = item.price
	if GameManager.is_debugging:
		cost_per_item = 0
		total_cost = 0
	
func _increase():
	var temp_quantity:int = quantity
	var plus:int = 1 if not Input.is_action_pressed("modifier") else 10
	quantity = min(quantity + plus, max_value)
	if quantity != temp_quantity: # If quantity changed by this
		update_label()

func _decrease():
	var temp_quantity:int = quantity
	var minus:int = 1 if not Input.is_action_pressed("modifier") else 10
	quantity = max(quantity - minus, min_value)
	if quantity != temp_quantity: # If quantity changed by this
		update_label()
		
func _changed(value: float):
	if quantity != value:
		quantity = clamp(value, min_value, max_value)
		update_label()
	
func update_label():
	number_label.value = quantity
	update_cost_label()

func update_cost_label():
	if cost_label:
		cost_label.text = "Cost: $" + str(quantity * cost_per_item)
		total_cost = quantity * cost_per_item
		if GameManager.is_debugging:
			total_cost = 0
			cost_label.text = "Cost: FREE"
