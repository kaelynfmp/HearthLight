extends Node2D


const boundary_atlas_pos:Vector2i = Vector2i(0, 0)
const offsets:Array[Variant]      = [
									Vector2i(0, -1),
									Vector2i(0, 1),
									Vector2i(1, 0),
									Vector2i(-1, 0)
									]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var base_layer = $Base
	var exclusions = base_layer.get_used_cells()

	for layer:TileMapLayer in self.find_children("", "TileMapLayer"):
		var cur_exclusions = exclusions.duplicate(true)
		for idx in len(cur_exclusions):
			# account for verticality of next layer
			cur_exclusions[idx] -= Vector2i(layer.z_index, layer.z_index)
		place_boundaries(layer, cur_exclusions)




func place_boundaries(layer, exclusions=[]):
	var used = layer.get_used_cells()
	for tile in used:
		for offset in offsets:
			var current_tile = tile + offset
			if not current_tile in exclusions:
				if layer.get_cell_source_id(current_tile) == -1:
					# nothing present
					layer.set_cell(current_tile, 0, boundary_atlas_pos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
