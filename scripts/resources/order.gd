@tool
class_name Order
extends Resource

@export_category("Order Details")
@export var order_id: int
var is_completed: bool = false
var is_accepted: bool = false
var responded: bool = false
@export var given_items: Array[Resource] = []:
	set(value):
		if given_quantities.size() != value.size():
			given_quantities.resize(value.size())
		given_items = value
@export var given_quantities: Array[int] = []:
	get:
		if Engine.is_editor_hint():
			for index in range(given_quantities.size()):
				given_quantities[index] = max(1, given_quantities[index])
		return given_quantities
	set(value):
		if given_items.size() != value.size():
			given_items.resize(value.size())
		given_quantities = value
@export var given_currency: int = 0
@export_category("Order Requirements")
@export var required_items: Array[Resource] = []:
	set(value):
		if required_quantities.size() != value.size():
			required_quantities.resize(value.size())
		required_items = value
		
@export var required_quantities: Array[int] = []:
	get:
		if Engine.is_editor_hint():
			for index in range(required_quantities.size()):
				required_quantities[index] = max(1, required_quantities[index])
		return required_quantities
	set(value):
		if required_items.size() != value.size():
			required_items.resize(value.size())
		required_quantities = value

@export_category("Due Date")
@export var day: int 
@export_range(8, 23, 1) var hour: int # min 0, max 30, step 1
@export_range(0, 59, 1) var minute: int

@export_category("Order Rewards")
@export var currency_reward: int = 0
@export var rewards: Array[Resource] = []:
	set(value):
		if rewards_quantities.size() != value.size():
			rewards_quantities.resize(value.size())
		rewards = value
@export var rewards_quantities: Array[int] = []:
	get:
		if Engine.is_editor_hint():
			for index in range(rewards_quantities.size()):
				rewards_quantities[index] = max(1, rewards_quantities[index])
		return rewards_quantities
	set(value):
		if rewards.size() != value.size():
			rewards.resize(value.size())
		rewards_quantities = value

# should ensure that the array size matches up sometime in the future

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func get_order() -> Array:
	return [required_items, required_quantities]
	
func set_completed(completed: bool) -> void:
	if completed:
		is_completed = true
		print("Order ", order_id, " completed")

func set_accepted(accepted: bool) -> void:
	if accepted:
		is_accepted = true
		print("Order ", order_id, " accepted")

func is_completable() -> bool:
	if GameManager.player_inventory_has(required_items, required_quantities):
		return true
	return false

func missed_deadline_consequence():
	pass
