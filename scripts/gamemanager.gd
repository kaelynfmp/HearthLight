extends Node

signal inventory_changed

@export var inventory:bool = false

var cursor:Node2D

var inventories: Array[Inventory] = []

var slot_distributor: Dictionary = {"total": 0, "item": null, "slots": [], "distributed": []} 

const MAX: int = 999999999999999999

func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		change_inventory()

func change_inventory():
	if inventory:
		inventory = false
		inventories.clear()
	else:
		inventory = true
	inventory_changed.emit()

func add_inventory(p_inventory: Inventory):
	inventories.append(p_inventory)

func send_to_inventory(slot: Slot):
	var went_somewhere: bool = false
	var home_inventory: Inventory
	var temp_slot: Slot = slot.duplicate()
	for search_inventory in inventories:
		if slot not in search_inventory.slots:
			slot.decrement(slot.quantity)
			went_somewhere = search_inventory.insert(temp_slot.item, temp_slot.quantity)
			return
		else:
			home_inventory = search_inventory

	if !went_somewhere:
		slot.decrement(slot.quantity)
		home_inventory.insert(temp_slot.item, temp_slot.quantity)

func set_cursor(setting_cursor: Node2D):
	cursor = setting_cursor
	
### Appends to the slot distributor, which is a list of currently dragged over slots, and will balance out how many items
### are in them all, with a total quantity and an item
func initialize_slot_distributor(total: int, item: Item):
	slot_distributor.total = total
	slot_distributor.item = item

### Appends to the slot distributor, which is a list of currently dragged over slots, and will balance out how many items
### are in them all
func append_slot_distributor(slot: Slot, add: int = 0) -> bool:
	if slot not in slot_distributor.slots and slot.can_insert(slot_distributor.item):
		slot_distributor.total += add
		slot_distributor.slots.append(slot)
		distribute_slots()
		return true
	return false
	
### Distributes the slots evenly among every slot in the slot distributor
func distribute_slots() -> void:
	var remainder = slot_distributor.total
	slot_distributor.distributed.resize(slot_distributor.slots.size())
	slot_distributor.distributed.fill(0)
	while remainder > 0:
		for index: int in range(slot_distributor.slots.size()):
			slot_distributor.distributed[index] += 1
			remainder -= 1
			if remainder == 0:
				for subindex: int in range(slot_distributor.slots.size()):
					slot_distributor.slots[subindex].initialize(slot_distributor.item, slot_distributor.distributed[subindex])
				return
	
### Clears the slot distributor, which is a list of currently dragged over slots, and will balance out how many items
### are in them all
func clear_slot_distributor():
	slot_distributor.total = 0
	slot_distributor.item = null
	slot_distributor.slots = []
