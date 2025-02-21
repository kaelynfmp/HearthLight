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
	var mouse_pos = get_local_mouse_position()
	var cell_pos = base_layer.local_to_map(mouse_pos)
	if cell_pos:
		var lowest_layer = get_lowest_available_tile(cell_pos)
		var index = lowest_layer["layer_relative_index"]
		var lowest = lowest_layer["layer_name"]
		if lowest != "":
			marker.position = base_layer.map_to_local(cell_pos)
			marker.z_index = 11 - index

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		spawnObject()
		
func get_lowest_available_tile(cell_pos: Vector2i) -> Dictionary:
	
	var lowest = ""
	var lowest_index = 0
	#for i in range(len(layers) - 1, -1, -1):
		#var layer_name = layers[i].get_name()
		#if cell_pos in tile_map[layer_name]:
			#if (i > 0) and (cell_pos + Vector2i(-1, -1)) not in tile_map[layers[i - 1].get_name()]:
				#lowest = layer_name
				#index = i
				#break
			#elif i == 0:
				#lowest = layer_name
				#index = i
	#for index in range(len()):
		#var layer_name = 
	return {"layer_name": lowest, "layer_relative_index": lowest_index}

func spawnObject() -> void:
	# Check if in used tile
	var mouse_pos = get_local_mouse_position()
	var cell_pos = base_layer.local_to_map(mouse_pos)
	var lowest_layer = get_lowest_available_tile(cell_pos)
	var lowest = lowest_layer["layer_name"]
	var index = lowest_layer["layer_relative_index"]

	if lowest != "":
		#print(lowest)
		var gadget = load("res://scenes/gadgets/gadget.tscn")
		var instance = gadget.instantiate()
		instance.set_name("Gadget")
		instance.z_index = 11 - index
		instance.position = base_layer.map_to_local(cell_pos)
		var layer = find_child(lowest)
		layer.add_child(instance)
		var layer_occupied_index = 10 - index
		var layer_occupied_name = "Layer %d"% (layer_occupied_index + 1)
		if layer_occupied_name not in tile_map:
			tile_map[layer_occupied_name] = []
		tile_map[layer_occupied_name].append(cell_pos + Vector2i(-1, -1))
		#print("Placed")
