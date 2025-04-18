extends Node
## For finding an email by the order that exists in it
var email_by_order:Dictionary[Order, Email]
var accepted_orders: Array = []
signal order_accepted(order:Order)
@onready var inventory: Inventory = preload("res://resources/character/inventory.tres")
@export var order_class : Resource
		
func accept_order(order: Order):
	order.is_accepted = true
	order.responded = true
	accepted_orders.append(order)
	order_accepted.emit(order)

func reject_order(order: Order):
	order.is_accepted = false
	order.responded = true

func check_due(_order: Order):
	pass

func archive_order(_order: Order): # unfulfilled by due date OR rejected
	pass
	
func fulfill_order(order: Order) -> bool:
	
	#check fulfillment ability
	if GameManager.is_debugging or check_fulfillment_ability(order):
		#GameManager.add_currency(50)
		var required_items = order.required_items
		var required_qtys = order.required_quantities
		for i in range(len(order.required_items)):
			remove_items_from_inventory(required_items[i],required_qtys[i])
		reward_player(order)
		order.set_completed(true)
		return true
	
	# if false:
	return false

func check_fulfillment_ability(order: Order) -> bool:
	if len(order.required_items) == 0:
		return true
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
