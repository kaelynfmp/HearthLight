@tool
class_name Order
extends Resource

@export_category("Order Details")
@export var order_id: int
var is_completed: bool = false
var is_accepted: bool = false
var responded: bool = false

@export_category("Order Requirements")
@export var required_items: Array[Resource] = []
@export var required_quantities: Array[int] = []
@export var rewards: Array[Resource] = []
@export var rewards_quantities: Array[Resource] = []
# should ensure that the array size matches up sometime in the future

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
