extends StaticBody2D
@export var item: Item
@export var move_speed: int = 320
@export var target_position: Vector2 = Vector2(-100, -100)
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

func _physics_process(delta: float) -> void:
	if len(path) > 0 and global_position == path[0]:
		path.pop_front()
	var current_pos = tile_layer.local_to_map(global_position) - Vector2i(-1, -1)
	var current_gadget = GameManager.room_map[current_pos[0] + 6][current_pos[1] + 5]
	if current_gadget.gadget_stats.name != "Conveyor Belt":
		current_gadget.inventory.insert(item, 1)
		queue_free()
		return
	var direction = current_gadget.direction
	var target_cell_pos = current_pos + direction_vectors[direction]
	var next_gadget = GameManager.room_map[target_cell_pos[0] + 6][target_cell_pos[1] + 5]
	if next_gadget != null:
		var target_pos = tile_layer.map_to_local(target_cell_pos + Vector2i(-1, -1))
		if not target_pos in path:
			path.append(target_pos)
	if len(path) > 0:
		global_position = global_position.move_toward(path[0], delta * move_speed)
