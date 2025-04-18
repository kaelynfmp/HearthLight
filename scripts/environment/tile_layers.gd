extends Node2D

const boundary_atlas_pos:Vector2i = Vector2i(0, 0)
const offsets:Array[Variant]      = [
									Vector2i(0, -1),
									Vector2i(0, 1),
									Vector2i(1, 0),
									Vector2i(-1, 0)
									]
var tile_map: Dictionary = {}

var item_map: Dictionary = {}

@onready var marker: Node2D = get_node("Marker") # Child Node2D

var base_layer: Node2D

var first_layer: Node2D

var is_placing: String = "Gadget" # Change this to place Pipe

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	base_layer = $Base
	first_layer = $"Layer 1"
	var exclusions = base_layer.get_used_cells()
	
	for layer:TileMapLayer in self.find_children("", "TileMapLayer"):
		var cur_exclusions = exclusions.duplicate(true)
		for idx in len(cur_exclusions):
			# account for verticality of next layer
			cur_exclusions[idx] -= Vector2i(layer.z_index, layer.z_index)
		place_boundaries(layer, cur_exclusions)
		
	spawn_object(GameManager.computer_gadget, Vector2i(-6, -5))

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
		if (is_base_available(cell_pos)):
			marker.is_uni_generator = false
			marker.is_generator = false
			if GameManager.get_gadget_from_cursor().name == "Universal Generator":
				marker.is_uni_generator = true
				marker.position = Vector2i(0, 0)
			elif GameManager.get_gadget_from_cursor().name == "Generator":
				marker.is_generator = true
				marker.position = base_layer.map_to_local(cell_pos)
			else:
				marker.position = base_layer.map_to_local(cell_pos)
			marker.z_index = 0
			marker.visible = true
		else:
			marker.visible = false
			
	else:
		marker.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.is_placing_gadget and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if spawn_object(GameManager.get_gadget_from_cursor()):
			GameManager.cursor.slot.decrement()
			AudioManager.play_button_sound(AudioManager.BUTTON.PUT_DOWN, 0.0, 1.0, 0.0)
			#GameManager.change_inventory()
		
func is_base_available(cell_pos: Vector2i) -> bool:
	if cell_pos in tile_map["Base"]:
		if (cell_pos + Vector2i(-1, -1)) not in tile_map["Layer 1"]:
			return true
	return false

## Spawns a provided gadget onto the tilemap
func spawn_object(gadget: Gadget, _cell_pos:Vector2i = Vector2i(-99, -99)) -> bool:
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
		GameManager.room_map[cell_pos[0] + 6][cell_pos[1] + 5] = instance 
		instance.removing.connect(free_tile)
		instance.item_at_location.connect(item_at_location)
		instance.add_to_group("world_gadgets")
		$"Base".add_child(instance)
		# Set to lowest, so items are always above
		$"Base".move_child(instance, 0)
		tile_map[layer_occupied_name].append(cell_pos + Vector2i(-1, -1))
		if gadget.name == "Universal Generator":
			GameManager.has_cyber_generator = true
			GameManager.cyber_generator = instance
		return true
	return false
		
func free_tile(layer_occupied_name:String, cell_pos:Vector2i):
	tile_map[layer_occupied_name].remove_at(tile_map[layer_occupied_name].find(cell_pos + Vector2i(-1, -1)))
	GameManager.room_map[cell_pos[0]][cell_pos[1]] = null


func item_at_location(cell_pos: Vector2i, item: Item):
	var in_world_item = load("res://scenes/in_world_item.tscn")
	var item_instance = in_world_item.instantiate()
	item_instance.global_position = base_layer.map_to_local(cell_pos)
	item_instance.item = item
	item_instance.cell_pos = cell_pos
	item_instance.tile_layer = $"Base"
	$"Base".add_child(item_instance)
	# Set to highest, so items are always above
	$"Base".move_child(item_instance, -1)
	item_instance.add_to_group("world_items")
