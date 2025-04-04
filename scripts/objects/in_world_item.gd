extends StaticBody2D
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

func _physics_process(delta: float) -> void:
	var current_pos = tile_layer.local_to_map(global_position)
	var current_gadget = GameManager.room_map[current_pos[0] + 6][current_pos[1] + 5]
	if len(path) > 0 and global_position == path[0]:
		path.pop_front()
	if current_gadget == null:
		#GameManager.send_to_inventory()
		GameManager.player_inventory.insert(item, 1)
		queue_free()
		return
	if current_gadget.gadget_stats.name != "Conveyor Belt":
		var availble_slots: Array[Slot] = current_gadget.inventory.slots.filter(func(slot): 
			return !slot.locked and (slot.item == null or (slot.item == item and slot.quantity < item.max_stack)))	
		if not availble_slots.is_empty():
			current_gadget.inventory.insert(item, 1)
			queue_free()
		return
	var direction = current_gadget.direction
	var target_cell_pos = current_pos + direction_vectors[direction]
	var next_gadget = GameManager.room_map[target_cell_pos[0] + 6][target_cell_pos[1] + 5]
	if next_gadget != null:
		var target_pos = tile_layer.map_to_local(target_cell_pos)
		var next_item =  GameManager.item_map[target_cell_pos[0] + 6][target_cell_pos[1] + 5]
		if not target_pos in path and (next_item == null):
			path.append(target_pos)
	if len(path) > 0:
		if cell_pos != current_pos:
			GameManager.item_map[cell_pos[0] + 6][cell_pos[1] + 5] = null
			GameManager.item_map[current_pos[0] + 6][current_pos[1] + 5] = self
			cell_pos = current_pos
		global_position = global_position.move_toward(path[0], delta * move_speed)
