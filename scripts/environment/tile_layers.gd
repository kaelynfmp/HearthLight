extends Node2D


const boundary_atlas_pos:Vector2i = Vector2i(0, 0)
const offsets:Array[Variant]      = [
									Vector2i(0, -1),
									Vector2i(0, 1),
									Vector2i(1, 0),
									Vector2i(-1, 0)
									]
var tile_map: Dictionary = {}

@onready var marker: Node2D = get_node("Marker") # Child Node2D

var base_layer: Node2D

var is_placing: String = "Gadget" # Change this to place Pipe

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	base_layer = $Base
	var exclusions = base_layer.get_used_cells()

	for layer:TileMapLayer in self.find_children("", "TileMapLayer"):
		var cur_exclusions = exclusions.duplicate(true)
		for idx in len(cur_exclusions):
			# account for verticality of next layer
			cur_exclusions[idx] -= Vector2i(layer.z_index, layer.z_index)
		place_boundaries(layer, cur_exclusions)
		
	spawnObject(GameManager.computer_gadget, Vector2i(-6, -5))

func place_boundaries(layer, exclusions=[]):
	var used = layer.get_used_cells()
	tile_map[layer.get_name()] = []
	for tile in used:
		for offset in offsets:
			var current_tile = tile + offset
			if not current_tile in exclusions:
				if layer.get_cell_source_id(current_tile) == -1:
					# nothing present
					layer.set_cell(current_tile, 0, boundary_atlas_pos)
		# We only deal with the first 3 layers since we do not allow gadget stacking
		if layer.get_name() in ["Base", "Layer 1", "Layer 2"]:
			tile_map[layer.get_name()].append(tile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if GameManager.is_placing_gadget:
		var mouse_pos = get_local_mouse_position()
		var cell_pos = base_layer.local_to_map(mouse_pos)
		if cell_pos:
			if (is_base_available(cell_pos)):
				marker.position = base_layer.map_to_local(cell_pos)
				marker.z_index = 0
				marker.visible = true
			else:
				marker.visible = false
	else:
		marker.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.is_placing_gadget and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if spawnObject(GameManager.get_gadget_from_cursor()):
			GameManager.cursor.slot.decrement()
			GameManager.change_inventory()
		
func is_base_available(cell_pos: Vector2i) -> bool:
	var lowest = ""
	var lowest_index = 0
	if cell_pos in tile_map["Base"]:
		if (cell_pos + Vector2i(-1, -1)) not in tile_map["Layer 1"]:
			return true
	return false

## Spawns a provided gadget onto the tilemap
func spawnObject(gadget: Gadget, _cell_pos:Vector2i = Vector2i(-99, -99)) -> bool:
	# Check if in used tile
	var mouse_pos = get_local_mouse_position()
	var cell_pos = base_layer.local_to_map(mouse_pos)
	if _cell_pos != Vector2i(-99, -99):
		cell_pos = _cell_pos
	if (is_base_available(cell_pos)):
		var gadget_scene = load("res://scenes/gadgets/gadget.tscn")
		var instance = gadget_scene.instantiate()
		instance.set_name("Gadget")
		instance.z_index = 1
		instance.position = base_layer.map_to_local(cell_pos)
		instance.gadget_stats = gadget
		var layer_occupied_name:String = "Layer 1"
		instance.layer_occupied_name = layer_occupied_name
		instance.cell_pos = cell_pos
		instance.removing.connect(free_tile)
		$Base.add_child(instance)
		tile_map[layer_occupied_name].append(cell_pos + Vector2i(-1, -1))
		return true
	return false
		
func free_tile(layer_occupied_name:String, cell_pos:Vector2i):
	tile_map[layer_occupied_name].remove_at(tile_map[layer_occupied_name].find(cell_pos + Vector2i(-1, -1)))
		
