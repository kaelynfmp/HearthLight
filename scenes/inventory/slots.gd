extends HFlowContainer

var inventory = load("res://resources/character/inventory.tres")
var prev_slots:int = 0

func add_slots():
	for child in get_children():
		child.free()
		
	for slot in inventory.slots:
		var new_scene:PanelContainer = load("res://scenes/inventory/inventory_slot.tscn").instantiate()
		new_scene.slot = slot
		add_child(new_scene)

func _process(_delta: float) -> void:
	if prev_slots != inventory.slots.size():
		prev_slots = inventory.slots.size()
		add_slots()
