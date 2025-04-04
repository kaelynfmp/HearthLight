extends Control
@export var selected_category: String
@export var category_label: Label
@export var items: Array = []
var base_resources: Array = ["seed", "water", "rock", "coal"]
var shop_dict = GameManager.shop_dict
var folder : String
var buttons = []
@export var item_container: Node
@export var item_button_scene : PackedScene
var unlocked:bool = false

func _ready() -> void:
	GameManager.debug_mode_change.connect(debug_visible)
	if GameManager.is_debugging:
		set_visible(true)

func set_category(category: String):
	selected_category = category
	category_label.text = selected_category.capitalize()
	folder = "res://resources/items/"
	if len(GameManager.shop_dict[category]) == 0:
		load_items(category)
	generate_wanted()
	for item in shop_dict[category]:
		display_items(item)
	if (selected_category == "gadgets" and GameManager.gadgets_unlocked) or (selected_category == "resources" and GameManager.resources_unlocked):
		set_visible(true)
		unlocked = true


func load_items(category):
	if category == "resources":
		for item in GameManager.items:
			if GameManager.is_debugging:
				if item not in GameManager.shop_dict["resources"]:
					shop_dict["resources"].append(item)
			elif item.name.to_lower() in base_resources and item not in GameManager.shop_dict["resources"]:
				GameManager.shop_dict["resources"].append(item)
	else:
		for gadget in GameManager.gadgets:
			if GameManager.is_debugging and gadget and gadget is Gadget and gadget.produces:
				if gadget not in GameManager.shop_dict["gadgets"]:
					GameManager.shop_dict["gadgets"].append(gadget.item)
			elif gadget and gadget is Gadget and gadget.produces:
				if gadget.item not in GameManager.shop_dict["gadgets"]:
					GameManager.shop_dict["gadgets"].append(gadget.item)

func unlock():
	set_visible(true)
	unlocked = true

func display_items(item: Item):
	var item_button = item_button_scene.instantiate() 
	item_button.set_item(item) 
	buttons.append(item_button)
	#email_button.pressed.connect(func(): show_email_details(email, email_button))  #calls function on click
	item_container.add_child(item_button)

func generate_wanted():
	var items_copy = items.duplicate()
	items_copy.shuffle()
	var random_wanted_items = items_copy.slice(0,3)
	for eachitem in random_wanted_items:
		shop_dict["wanted"].append(eachitem)
		

func debug_visible():
	if GameManager.is_debugging:
		set_visible(true)
