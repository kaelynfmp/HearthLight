extends Node

var items: Array = [] 
var shop_dict = {"resources": [], "gadgets": []}
@onready var categories_list_container: Node = $ScrollContainer/ShopCategoriesListContainer
@export var item_button_scene: PackedScene
@export var shop_category_scene: PackedScene
var loaded_items = false
var item_class : Resource
var item_folder : String = "res://resources/items/"
var category_scenes = []

# **** ITEMS ARE BOUGHT IN item_buy_popup.gd ****
func _ready():
	GameManager.debug_mode_change.connect(reload_categories)
	if shop_category_scene:
		#load_shop_items()
		create_shop_categories()
	
func reload_categories():
	GameManager.shop_dict = {"resources": [], "gadgets": []}
	if shop_category_scene:
		for category in category_scenes:
			categories_list_container.remove_child(category)
		category_scenes = []
		create_shop_categories()
		

#func display_item(item: Item): #insert item as a parameter
	#var item_button = item_button_scene.instantiate()  
	#item_button.set_item(item)
	##item_button.pressed.connect(func(): show_item_details(item)) 
	#categories_list_container.add_child(item_button)

#func load_shop_items():
	## RAW MATERIALS: seed, water, rock
		## load all email resources
	#var dir = DirAccess.open(item_folder)
	#if dir != null:
		#dir.list_dir_begin()
		#var file_name = dir.get_next()
		#while file_name != "":
			#if file_name.ends_with(".tres"):
				#var item_path = item_folder + file_name
				#var item = load(item_path)
				#if item and item is Item: # TODO: change in future for gadget upgrades, etc
					#if item.name.to_lower() in base_resources:
						#shop_dict["resources"].append(item)
					#else:
						#shop_dict["gadgets"].append(item)
						#
			#file_name = dir.get_next()
		#dir.list_dir_end()

func create_shop_categories():
	for category_name in shop_dict.keys():
		var shop_category = shop_category_scene.instantiate()
		shop_category.set_category(category_name)
		if category_name == "resources" or category_name == "gadgets":
			var num_items = len(GameManager.shop_dict[category_name])
			var num_rows = (num_items + 4) / 4
		GameManager.shop_categories[category_name] = shop_category
		category_scenes.append(shop_category)
		
		#inbox_button.text = category.capitalize()
		#inbox_button.pressed.connect(func(): display_category_emails(category)) 
		categories_list_container.add_child(shop_category)
	
