extends Node
var orders: Array = []
var accepted_orders: Array = []
var rejected_orders: Array = []
@onready var inventory: Inventory = preload("res://resources/character/inventory.tres")
@export var order_folder : String = "res://resources/orders/"
@export var order_class : Resource

func load_orders():
	# load all order resources
	var dir = DirAccess.open(order_folder)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var order_path = order_folder + file_name
				var order = load(order_path)
				if order and order is Order:
					orders.append(order)
			file_name = dir.get_next()
		dir.list_dir_end()
		
		
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
	
func check_fulfillment(order: Order):
	pass

func reward_player(order: Order):
	for i in range(0,len(order.rewards)):
		var item = order.rewards[i]
		var qty = order.rewards_quantities[i]
		GameManager.add_currency(order.currency_reward)
		inventory.insert(item, qty) #TODO: verify
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
