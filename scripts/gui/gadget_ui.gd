extends Control

@onready var input_slot_scene:PackedScene = preload("res://scenes/inventory/input_slot.tscn")
@onready var output_slot_scene:PackedScene = preload("res://scenes/inventory/output_slot.tscn")
@onready var creates_progress:TextureRect = find_child("CreatesProgress", true)
var current_gadget:Gadget

func _process(_delta: float) -> void:
	visible = GameManager.gadget != null
	if GameManager.gadget != null:
		if current_gadget == null:
			set_gadget(GameManager.gadget)
		if GameManager.gadget.progressing:
			creates_progress.visible = true
			creates_progress.material.set("shader_parameter/progress", GameManager.gadget.progress)
		else:
			creates_progress.visible = false
	else:
		current_gadget = null
	
func set_gadget(gadget:StaticBody2D):
	current_gadget = gadget.gadget_stats
	
	var inputs:Array[Slot] = gadget.inventory.slots.filter(func(slot): return !slot.locked)
	var outputs:Array[Slot] = gadget.inventory.slots.filter(func(slot): return slot.locked)
	var contained = $Background/Contained
	
	var remove_children:Array
	
	for child in contained.get_children():
		if "InputSlot" in child.name or "OutputSlot" in child.name:
			remove_children.append(child)
		
	# Not sure if needed, but didn't want to delete children as I was iterating over them		

	for child in remove_children:
		contained.remove_child(child)
		
	for index in range(inputs.size()):
		var input:Slot = gadget.inventory.slots[gadget.inventory.slots.find(inputs[index])]
		var new_slot:PanelContainer = input_slot_scene.instantiate()
		new_slot.set_slot(input)
		new_slot.update()
		new_slot.set_name("InputSlot" + str(index))
		if inputs.size() >= 3:
			if index % 2 == 1:
				new_slot.size_flags_vertical = SIZE_SHRINK_BEGIN
			else:
				new_slot.size_flags_vertical = SIZE_SHRINK_END
		else:
			new_slot.size_flags_vertical = SIZE_SHRINK_CENTER	
		contained.add_child(new_slot)
		contained.move_child(new_slot, index)
		
	var starting_index:int = contained.get_child_count()
	for index in range(outputs.size()):
		var output:Slot = gadget.inventory.slots[gadget.inventory.slots.find(outputs[index])]
		var new_slot:PanelContainer = output_slot_scene.instantiate()
		new_slot.set_slot(output)
		new_slot.update()
		new_slot.set_name("OutputSlot" + str(index))
		if outputs.size() >= 3:
			if index % 2 == 1:
				new_slot.size_flags_vertical = SIZE_SHRINK_BEGIN
			else:
				new_slot.size_flags_vertical = SIZE_SHRINK_END
		else:
			new_slot.size_flags_vertical = SIZE_SHRINK_CENTER
		contained.add_child(new_slot)
		contained.move_child(new_slot, starting_index + index)