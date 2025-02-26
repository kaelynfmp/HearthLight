extends Node
@export var item_name: Label
@export var item_desc: Label
@export var item_picture: TextureRect

# quantity select
@export var min_value: int = 1
@export var max_value: int = 99
@export var cost_per_item: int = 10 
@export var cost_label: Label
var current_value: int = 1  # Default quantity

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

func _buy():
	if GameManager.subtract_currency(total_cost) == true: # successful purchase
		queue_free()
		# ADD ITEM TO INVENTORY
		# current_value is the quantity
	else:
		pass
		# maybe show insufficient funds in future
		# show buy button as unavailable if currency not enough? future goal

func _close():
	queue_free()

func set_item_buy(item: Item):
	item_name.text = item.name
	item_desc.text = item.description
	item_picture.texture = item.texture
	cost_per_item = item.price
	total_cost = item.price
	
func _increase():
	if current_value < max_value:
		current_value += 1
		update_label()

func _decrease():
	if current_value > min_value:
		current_value -= 1
		update_label()

func update_label():
	number_label.text = str(current_value)
	update_cost_label()

func update_cost_label():
	if cost_label:
		cost_label.text = "Cost: $" + str(current_value * cost_per_item)
		total_cost = current_value * cost_per_item
