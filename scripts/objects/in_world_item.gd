extends StaticBody2D

class_name InWorldItem

@export var item: Item
@export var move_speed: int = 300
@export var target_position: Vector2
@export var offset: Vector2
@export var path: Array[Vector2] = []
@export var cell_pos: Vector2i
@export var tile_layer: TileMapLayer

# Forward direction (SE, SW, NW, NE)
var direction_vectors: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
]

func _ready() -> void:
	$CollisionShape2D/Sprite2D.texture = item.texture
	path = [global_position] 
	GameManager.item_map[cell_pos[0] + 6][cell_pos[1] + 5] = self
	
func check_for_one_stack(_item: Item, _gadget):
	var slots: Array[Slot] = _gadget.inventory.slots.filter(func(slot): return !slot.locked)
	if _gadget.gadget_stats.name == "Storage":
		return slots.any(func(slot): return slot.item == null or (slot.item.name == _item.name and slot.quantity < _item.max_stack))
		
	var found_slot = null
	for slot in slots:
		if slot.item != null and slot.item.name == _item.name:
			found_slot = slot
			break
	if found_slot != null:
		return found_slot.quantity < _item.max_stack
	return true
		

func _physics_process(delta: float) -> void:
	var next_gadget_available = false
	var current_pos = tile_layer.local_to_map(global_position)
	var current_gadget = GameManager.room_map[current_pos[0] + 6][current_pos[1] + 5]
	if len(path) > 0 and global_position == path[0]:
		path.pop_front()
	if current_gadget == null:
		GameManager.player_inventory.insert(item, 1)
		queue_free()
		return
	if current_gadget.gadget_stats.name != "Conveyor Belt":
		if check_for_one_stack(item, current_gadget):
			current_gadget.inventory.insert(item, 1)
			queue_free()
		return
	var direction = current_gadget.direction
	var target_cell_pos = current_pos + direction_vectors[direction]
	var next_gadget = GameManager.room_map[target_cell_pos[0] + 6][target_cell_pos[1] + 5]
	if next_gadget != null:
		if next_gadget.gadget_stats.name != "Conveyor Belt":
			next_gadget_available = check_for_one_stack(item, next_gadget)
		if next_gadget_available or next_gadget.gadget_stats.name == "Conveyor Belt":
			var target_pos = tile_layer.map_to_local(target_cell_pos)
			var next_item =  GameManager.item_map[target_cell_pos[0] + 6][target_cell_pos[1] + 5]
			if not target_pos in path and (next_item == null):
				path.append(target_pos)
	if len(path) > 0:
		if cell_pos != current_pos:
			GameManager.item_map[cell_pos[0] + 6][cell_pos[1] + 5] = null
			GameManager.item_map[current_pos[0] + 6][current_pos[1] + 5] = self
			cell_pos = current_pos
		var next_p = tile_layer.local_to_map(path[0])
		var next_g = GameManager.room_map[next_p[0] + 6][next_p[1] + 5]
		if next_g != null:
			global_position = global_position.move_toward(path[0], delta * move_speed)
