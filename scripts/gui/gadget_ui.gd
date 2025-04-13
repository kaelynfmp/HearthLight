extends Control

var rotation_speed:float = 10
@onready var input_slot_scene:PackedScene = preload("res://scenes/inventory/input_slot.tscn")
@onready var output_slot_scene:PackedScene = preload("res://scenes/inventory/output_slot.tscn")
@onready var slot_scene:PackedScene = preload("res://scenes/inventory/storage_slot.tscn")
@onready var creates_progress:TextureRect = find_child("CreatesProgress", true)
@onready var primitive_button:TextureButton = find_child("PrimitiveButton", true)
@onready var energy_progress:TextureRect = find_child("EnergyProgress", true)
var current_gadget:Gadget
var input_hint_dict: Dictionary = {}

func _ready() -> void:
	GameManager.gadget_changed.connect(_reset_gadget)

func _process(delta: float) -> void:
	visible = GameManager.gadget != null and GameManager.gadget.gadget_stats.name != "Conveyor Belt" and GameManager.gadget.gadget_stats.name != "Teleporter"
	if GameManager.gadget != null and GameManager.gadget.gadget_stats.name != "Conveyor Belt" and GameManager.gadget.gadget_stats.name != "Teleporter":
		if GameManager.gadget.progressing:
			creates_progress.visible = true
			creates_progress.material.set("shader_parameter/progress", GameManager.gadget.progress)
		else:
			creates_progress.visible = false
		primitive_button.disabled = GameManager.gadget.selected_recipe == null or not GameManager.gadget.is_able_to_do_recipe
		if primitive_button.disabled:
			primitive_button.set_rotation(0)
		GameManager.gadget.primitive_selected = primitive_button.is_pressed()
		if primitive_button.is_pressed():
			primitive_button.set_rotation(primitive_button.get_rotation() + rotation_speed * delta)
		if current_gadget.name == "Generator":
			energy_progress.visible = true
			energy_progress.material.set("shader_parameter/progress", GameManager.gadget.total_power / GameManager.gadget.max_power)
		else:
			energy_progress.visible = false
		if current_gadget.name == "Universal Generator":
			$Background/Contained/CreatesControl.visible = false
			$Background/Contained/InfinitePower.visible = true
			
		else:
			$Background/Contained/CreatesControl.visible = true
			$Background/Contained/InfinitePower.visible = false
	else:
		current_gadget = null
	if current_gadget and not current_gadget.name in ["Storage", "Universal Generator", "Teleporter"]:
		update_hint_visibility()
		
func _reset_gadget():
	if GameManager.gadget != null:
		set_gadget(GameManager.gadget)
	else:
		set_gadget(null)
	
func setup_storage(gadget: InWorldGadget):
	var inputs:Array[Slot] = gadget.inventory.slots.filter(func(slot): return !slot.locked)
	var contained = $Background/Contained
	contained.visible = false
	$Background/Contained/EnergyControl.visible = false
	var hflowcontainer = $Background/HFlowContainer
	hflowcontainer.visible = true
	var remove_children:Array
	for child in hflowcontainer.get_children():
		if "InputSlot" in child.name or "OutputSlot" in child.name or "StorageSlot" in child.name:
			remove_children.append(child)
	for child in remove_children:
		hflowcontainer.remove_child(child)
	for index in range(inputs.size()):
		var input:Slot = gadget.inventory.slots[gadget.inventory.slots.find(inputs[index])]
		var new_slot:PanelContainer = slot_scene.instantiate()
		new_slot.set_slot(input)
		new_slot.update()
		new_slot.set_name("StorageSlot" + str(index))
		hflowcontainer.add_child(new_slot) 
		hflowcontainer.move_child(new_slot, index)
		
func setup_teleporter(gadget: InWorldGadget):
	pass
		
func setup_generator(gadget: InWorldGadget):
	var contained = $Background/Contained
	# Setup coal slot
	if current_gadget.name == "Generator":
		$Background/Contained/EnergyControl.visible = true
		var inputs:Array[Slot] = gadget.inventory.slots.filter(func(slot): return !slot.locked)
		for index in range(inputs.size()):
			var input:Slot = gadget.inventory.slots[gadget.inventory.slots.find(inputs[index])]
			var new_slot: PanelContainer = input_slot_scene.instantiate()
			
			# VISUAL INPUT HINTS ON GADGETS
			var input_hint: TextureRect = new_slot.find_child("ImgHintInput", true)
			var recipe_inputs = get_inputs_for_hint()
			var curr_slot = recipe_inputs[index]
			if curr_slot == null:
				input_hint.texture = null
				continue
			input_hint.texture = curr_slot.item.texture
			input_hint_dict[input_hint] = current_gadget.inventory.get_item_quantity(curr_slot.item)
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
	else:
		$Background/Contained/EnergyControl.visible = false
	
func set_gadget(gadget:InWorldGadget):
	if gadget == null:
		current_gadget = null
		return
	primitive_button.set_rotation(0)
	current_gadget = gadget.gadget_stats
	primitive_button.visible = gadget.gadget_stats.age == GameManager.Age.PRIMITIVE
	
	if current_gadget.name == "Storage":
		setup_storage(gadget)
		return
	
	var inputs:Array[Slot] = gadget.inventory.slots.filter(func(slot): return !slot.locked)
	var outputs:Array[Slot] = gadget.inventory.slots.filter(func(slot): return slot.locked)
	var contained = $Background/Contained
	var hflowcontainer = $Background/HFlowContainer
	hflowcontainer.visible = false
	$Background/Contained/EnergyControl.visible = false
	$Background/Contained/InfinitePower.visible = false
	contained.visible = true
	var remove_children:Array
	
	for child in contained.get_children():
		if "InputSlot" in child.name or "OutputSlot" in child.name or "StorageSlot" in child.name:
			remove_children.append(child)
		
	# Not sure if needed, but didn't want to delete children as I was iterating over them		

	for child in remove_children:
		contained.remove_child(child)
		
	if "Generator" in current_gadget.name:
		setup_generator(gadget)
		return
		
	if current_gadget.name == "Teleporter":
		setup_teleporter(gadget)
		return
		
	for index in range(inputs.size()):
		var input:Slot = gadget.inventory.slots[gadget.inventory.slots.find(inputs[index])]
		var new_slot:PanelContainer = input_slot_scene.instantiate()
		
		# VISUAL INPUT HINTS ON GADGETS
		var input_hint:TextureRect = new_slot.find_child("ImgHintInput", true)
		var recipe_inputs = get_inputs_for_hint()
		var curr_slot = recipe_inputs[index]
		if curr_slot == null:
			input_hint.texture = null
			continue
		input_hint.texture = curr_slot.item.texture
		input_hint_dict[input_hint] = current_gadget.inventory.get_item_quantity(curr_slot.item)
		
		
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
	
		var output_hint:TextureRect = new_slot.find_child("ImgHintOutput", true)
		var recipe_outputs = get_outputs_for_hint()
		var curr_slot = recipe_outputs[index]
		if curr_slot.item == null:
			output_hint.texture = null
			continue
		output_hint.texture = curr_slot.item.texture

func get_inputs_for_hint():
		var recipes = GameManager.recipes
		var recipe: Recipe
		for eachrecipe in recipes:
			if eachrecipe.gadget == current_gadget:
				recipe = eachrecipe
				break
		return recipe.inputs

func get_outputs_for_hint():
		var recipes = GameManager.recipes
		var recipe: Recipe
		for eachrecipe in recipes:
			if eachrecipe.gadget == current_gadget:
				recipe = eachrecipe
				break
		return recipe.outputs

func update_hint_visibility():
	var quantities = []
	var recipe_inputs = get_inputs_for_hint()
	var inputs:Array[Slot] = current_gadget.inventory.slots.filter(func(slot): return !slot.locked)
	for index in range(inputs.size()):
		quantities.append(current_gadget.inventory.get_item_quantity(recipe_inputs[index].item))
	var i = 0
	for texture in input_hint_dict:
		if i in quantities:
			input_hint_dict[texture] = quantities[i]
		i+=1
		if input_hint_dict[texture] > 0:
			texture.visible = false
		else:
			texture.visible = true
