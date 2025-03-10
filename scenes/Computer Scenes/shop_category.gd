extends Control
@export var selected_category: String
@export var category_label: Label
@export var items: Array = []
var base_resources: Array = ["seed", "water", "rock"]
var shop_dict = GameManager.shop_dict
var folder : String
var buttons = []
@export var item_container: Node
@export var item_button_scene : PackedScene

func set_category(category: String):
	selected_category = category
	category_label.text = selected_category.capitalize()
	folder = "res://resources/items/"
	if len(shop_dict[category]) == 0:
		load_items(category)
	for item in shop_dict[category]:
		display_items(item)
	

func load_items(category):
	if category == "resources":
		var dir = DirAccess.open(folder)
		if dir != null:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".remap"):
					file_name = file_name.trim_suffix(".remap")
				if file_name.ends_with(".tres"):
					var item_path = folder + file_name
					var item = load(item_path)
					if item and item is Item:
						if GameManager.is_debugging:
							item.price = 0
							if item not in shop_dict["resources"]:
								shop_dict["resources"].append(item)
						
						elif item.name.to_lower() in base_resources and item not in shop_dict["resources"]:
							shop_dict["resources"].append(item)
				file_name = dir.get_next()
			dir.list_dir_end()
	else:
		folder = "res://resources/gadgets/"
		var dir2 = DirAccess.open(folder)
		if dir2 != null:
			dir2.list_dir_begin()
			var file_name = dir2.get_next()
			while file_name != "":
				if file_name.ends_with(".remap"):
					file_name = file_name.trim_suffix(".remap")
				if file_name.ends_with(".tres"):
					var gadget_path = folder + file_name
					var gadget = load(gadget_path)
					if GameManager.is_debugging:
						gadget.item.price = 0
						if gadget not in shop_dict["gadgets"]:
							shop_dict["gadgets"].append(gadget.item)
					elif gadget and gadget is Gadget and gadget.produces:
						if gadget.item not in shop_dict["gadgets"]:
							shop_dict["gadgets"].append(gadget.item)
				file_name = dir2.get_next()
			dir2.list_dir_end()


func display_items(item: Item):
	var item_button = item_button_scene.instantiate() 
	item_button.set_item(item) 
	buttons.append(item_button)
	#email_button.pressed.connect(func(): show_email_details(email, email_button))  #calls function on click
	item_container.add_child(item_button)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
