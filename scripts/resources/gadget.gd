@tool
@icon("res://resources/resource-icons/gadget.svg")

class_name Gadget

extends Resource

## Texture that represents the sprite in-game.
@export var texture: Texture2D
## Name of the gadget as it appears in-game.
@export var name: String:
	get():
		if item != null:
			item.name = name
		return name
		
## Age of the gadget (Primitive | Industrial | Electrical | Cyber)
enum Age {PRIMITIVE, INDUSTRIAL, ELECTRICAL, CYBER}
@export var age: Age

enum Direction {SE, SW, NW, NE}
@export var direction: Direction = 0

## In-game description of the gadget.
@export_multiline var description: String:
	get():
		if item != null:
			item.description = description
		return description

@export_category("Properties")
## Item corresponding to the gadget for inventory usage
var prev_item_texture
@export var item: Item:
	get():
		if Engine.is_editor_hint():
			if item != null:
				if item.texture != null:
					if item.texture != prev_item_texture:
						item.changed.emit()
						prev_item_texture = item.texture
				elif prev_item_texture != null:
					item.changed.emit()
					prev_item_texture = null
		return item
## Initial inventory that belongs to the gadget
@export var inventory: Inventory :
	get():
		if inventory == null:
			inventory = load("res://scripts/resources/inventory.gd").new()
		return inventory
## Whether or not this gadget can have recipes
@export var produces: bool
## The amount of inputs a recipe from this gadget can take
@export var inputs: int:
	get():
		if inventory.slots.size() != inputs + outputs:
			var temp_inventory_slots:Array[Slot] = inventory.slots.duplicate()
			temp_inventory_slots.resize(inputs + outputs)
			inventory.slots = temp_inventory_slots
			for index in range(inventory.slots.size()):
				var slot = inventory.slots[index]
				slot.locked = index >= inputs
		return max(1, inputs)
## The amount of outputs this gadget can produce
@export var outputs: int:
	get():
		return max(1, outputs)
## The amount of time it takes to process a recipe
@export var process_time: float
## The sound that play when the gadget is started
@export var start_sound: AudioStream
## The sound that play during the gadget progress
@export var ambient_sound: AudioStream
## The sound that play when the gadget is stopped
@export var stop_sound: AudioStream

func _init(p_texture: Texture2D = null, p_name: String = "", p_description: String = "", p_item: Item = null, \
		   p_inventory: Inventory = null, p_produces: bool = false, p_inputs: int = 0, p_outputs: int = 0, \
		   p_process_time: float = 0.0, p_start_sound: AudioStream = null, p_ambient_sound: AudioStream = null, p_stop_sound: AudioStream = null):
	texture = p_texture
	name = p_name
	description = p_description
	item = p_item
	inventory = p_inventory
	produces = p_produces
	inputs = p_inputs
	outputs = p_outputs
	process_time = p_process_time
	start_sound = p_start_sound
	ambient_sound = p_ambient_sound
	stop_sound = p_stop_sound
