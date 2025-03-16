extends Node
var orders: Array = []
var accepted_orders: Array = []
var rejected_orders: Array = []
@onready var inventory: Inventory = preload("res://resources/character/inventory.tres")
@export var order_class : Resource

func load_orders():
	var email_strings = Utility.load_path("res://resources/emails")
	for email_string in email_strings:
		var email = load(email_string)
		if email.attached_order != null:
			orders.append(email.attached_order)
		
		
func accept_order(order: Order):
	order.is_accepted = true
	order.responded = true
	accepted_orders.append(order)

func reject_order(order: Order):
	order.is_accepted = false
	order.responded = true
	rejected_orders.append(order)

func check_due(order: Order):
	pass

func archive_order(order: Order): # unfulfilled by due date OR rejected
	pass
	
func fulfill_order(order: Order) -> bool:
	
	#check fulfillment ability
	if check_fulfillment_ability(order):
		#GameManager.add_currency(50)
		var required_items = order.required_items
		var required_qtys = order.required_quantities
		for i in range(len(order.required_items)):
			remove_items_from_inventory(required_items[i],required_qtys[i])
		reward_player(order)
		order.set_completed(true)
		return true
	# if true:
	# remove items
	# reward player
	# TODO: archive order
	
	# if false:
	return false

func check_fulfillment_ability(order: Order) -> bool:
	return GameManager.player_inventory_has(order.required_items, order.required_quantities)

func remove_items_from_inventory(item: Item, qty: int):
	inventory.remove_items(item,qty)

func reward_player(order: Order):
	GameManager.add_currency(order.currency_reward)
	if len(order.rewards) > 0:
		for i in range(0,len(order.rewards)):
			var item = order.rewards[i]
			if item is Gadget:
				item = item.item
			var qty = order.rewards_quantities[i]
			inventory.insert(item, qty)

func give_player_starting_items(order: Order):
	if len(order.given_items)>0:
		for i in range(0,len(order.given_items)):
			var item = order.given_items[i]
			if item is Gadget:
				item = item.item
			var qty = order.given_quantities[i]
			inventory.insert(item, qty)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
