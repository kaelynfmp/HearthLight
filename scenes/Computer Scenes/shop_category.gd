extends Label
@export var selected_category: String
@export var category_label: Label
@export var items: Array = []
var base_resources: Array = ["seed", "water", "rock", "cotton"]
var gadget_show: Array = []
var shop_dict = GameManager.shop_dict
var folder : String
@export var item_container: Node
@export var item_button_scene : PackedScene

func set_category(category: String):
	selected_category = category
	category_label.text = selected_category.capitalize()
	folder = "res://resources/items/"
	if len(shop_dict[category]) == 0:
		load_items()
	print(shop_dict[category])
	for item in shop_dict[category]:
		display_items(item)

	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func load_items():
	var dir = DirAccess.open(folder)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var item_path = folder + file_name
				var item = load(item_path)
				if item and item is Item:
					print("Loaded item")
					if item.name.to_lower() in base_resources and item not in shop_dict["resources"]:
						shop_dict["resources"].append(item)
					elif item.name.to_lower() in gadget_show and item not in shop_dict["resources"]:
						shop_dict["gadgets"].append(item)
					else:
						pass
			file_name = dir.get_next()
		dir.list_dir_end()


func display_items(item: Item):
	var item_button = item_button_scene.instantiate() 
	item_button.set_item(item) 
	#email_button.pressed.connect(func(): show_email_details(email, email_button))  #calls function on click
	item_container.add_child(item_button)
	print("Added item: ", item.name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
