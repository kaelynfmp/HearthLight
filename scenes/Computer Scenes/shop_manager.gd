extends Node

var items: Array = [] 
var shop_dict = {"resources": [], "gadgets": []}
@onready var categories_list_container: Node = $ScrollContainer/ShopCategoriesListContainer
@export var item_button_scene: PackedScene
@export var shop_category_scene: PackedScene
@onready var sell_panel: Node = $SellPanel
@onready var open_sell_button: Node = $SellButton
var loaded_items = false
var item_class : Resource
var item_folder : String = "res://resources/items/"
var category_scenes = []

# **** ITEMS ARE BOUGHT IN item_buy_popup.gd ****
func _ready():
	GameManager.debug_mode_change.connect(reload_categories)
	open_sell_button.pressed.connect(on_sell_button_pressed)
	open_sell_button.disabled = true
	sell_panel.visible = false
	if shop_category_scene:
		#load_shop_items()
		create_shop_categories()

func _process(delta: float) -> void:
	if open_sell_button.disabled:
		if GameManager.check_core_tutorials_done():
			open_sell_button.disabled = false

func reload_categories():
	GameManager.shop_dict = {"resources": [], "gadgets": []}
	if shop_category_scene:
		for category in category_scenes:
			categories_list_container.remove_child(category)
		category_scenes = []
		create_shop_categories()

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

func on_sell_button_pressed():
	sell_panel.visible = true
	GameManager.change_inventory()
