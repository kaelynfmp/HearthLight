extends Node

var items: Array = [] 
@onready var categories_list_container: Node = $ScrollContainer/ShopCategoriesListContainer
@export var item_button_scene: PackedScene
@export var shop_category_scene: PackedScene

@export var item_class : Resource
var item_folder : String = "res://resources/items/"
var categorized_items: Dictionary = {
	"items": []
}

func _ready():
	load_shop_items()
	create_shop_categories()
	#create_inbox_buttons()
	#print(emails)
	#display_category_emails("main") # default view to "main"
	
func add_item():
	pass
	#var item = item_class.new()  
	#items.append(item) 
	#display_item(item)  # Add to UI
func add_gadget():
	pass
# adds items to shop ui
func display_item(item: Item): #insert item as a parameter
	var item_button = item_button_scene.instantiate()  
	item_button.set_item(item)
	#item_button.pressed.connect(func(): show_item_details(item)) 
	categories_list_container.add_child(item_button)

func load_shop_items():
	# RAW MATERIALS: seed, water, rock
		# load all email resources
	var dir = DirAccess.open(item_folder)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var item_path = item_folder + file_name
				var item = load(item_path)
				if item and item is Item:
					categorized_items["items"].append(item)
			file_name = dir.get_next()
		dir.list_dir_end()

func create_shop_categories():
		var shop_category = shop_category_scene.instantiate()
		shop_category.set_category("items")
		#inbox_button.text = category.capitalize()
		#inbox_button.pressed.connect(func(): display_category_emails(category)) 
		categories_list_container.add_child(shop_category)
# shows upon click

func buy_item(item: Item, qty: int):
	pass
	#TODO: confirm sufficient currency
	#TODO: confirm sufficient inventory space
	#TODO: add item to inventory, subtract currency

func sell_item(item: Item, qty: int):
	pass
	#TODO: confirm possession of items for selling
	#TODO: remove item from inventory, add currency
#func show_item_details(item: Item, item_button: Button): #confirm item buy???
	
