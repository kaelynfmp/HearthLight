extends Node
var item: Item
@export var item_name: Label
@export var item_desc: Label
@export var item_picture: TextureRect
@onready var inventory: Inventory = preload("res://resources/character/inventory.tres")

# quantity select
@export var min_value: int = 1
@export var max_value: int = 99
@export var cost_per_item: int = 10 
@export var cost_label: Label
var quantity: int = 1  # Default quantity

@export var number_label: Label
@export var minus_button: Button
@export var plus_button: Button

@export var buy_button: Button
@export var decline_button: Button
var total_cost: int

func _ready():
	update_label()
	minus_button.connect("pressed", Callable(self, "_decrease"))
	plus_button.connect("pressed", Callable(self, "_increase"))
	buy_button.connect("pressed", Callable(self, "_buy"))
	decline_button.connect("pressed", Callable(self, "_close"))

func _process(delta: float) -> void:
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
			inventory.insert(item, quantity)
			queue_free()
			return
		else:
			# TODO: proper error handling
			GameManager.add_currency(total_cost)
			print("Error inserting bought item into inventory")
		
	else:
		pass
		# maybe show insufficient funds in future
		# show buy button as unavailable if currency not enough? future goal


func set_item_buy(new_item: Item):
	item = new_item
	item_name.text = item.name
	item_desc.text = item.description
	item_picture.texture = item.texture
	cost_per_item = item.price
	total_cost = item.price
	
func _increase():
	if quantity < max_value:
		quantity += 1
		update_label()

func _decrease():
	if quantity > min_value:
		quantity -= 1
		update_label()

func update_label():
	number_label.text = str(quantity)
	update_cost_label()

func update_cost_label():
	if cost_label:
		cost_label.text = "Cost: $" + str(quantity * cost_per_item)
		total_cost = quantity * cost_per_item
