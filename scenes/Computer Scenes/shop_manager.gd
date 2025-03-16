extends Node

var items: Array = [] 
var shop_dict = GameManager.shop_dict
@onready var categories_list_container: Node = $ScrollContainer/ShopCategoriesListContainer
@export var item_button_scene: PackedScene
@export var shop_category_scene: PackedScene
var loaded_items = false
var item_class : Resource
var item_folder : String = "res://resources/items/"

# **** ITEMS ARE BOUGHT IN item_buy_popup.gd ****
func _ready():
	if shop_category_scene:
		#load_shop_items()
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
		var size_to_items = int(ceil(shop_dict[category_name].size() / 4.0))
		shop_category.custom_minimum_size = Vector2(1920,550*size_to_items)
		#if category_name == "resources" or category_name == "gadgets":
			#shop_category.custom_minimum_size = Vector2(1920,650)
		#inbox_button.text = category.capitalize()
		#inbox_button.pressed.connect(func(): display_category_emails(category)) 
		categories_list_container.add_child(shop_category)
	
