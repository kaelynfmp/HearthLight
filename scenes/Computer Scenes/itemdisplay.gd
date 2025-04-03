extends Button

@export var item: Item

@export var name_label: Label
@export var price_label: Label
@export var item_image: TextureRect
@export var popup_scene: PackedScene 

@export var button_sound: AudioManager.BUTTON

func set_item(new_item: Item):
	item = new_item
	name_label.text = item.name
	price_label.text = "$"+str(item.price)
	if GameManager.is_debugging:
		price_label.text = "FREE"
	item_image.texture = item.texture
	GameManager.buyable_items[item] = self

func set_limited_text(input_text: String, limit: int = 16) -> String:
	if input_text.length() > limit:
		return input_text.substr(0, limit) + "..." 
	else:
		return input_text
	
func _ready() -> void:
	connect("pressed", Callable(self, "_show_popup"))
	
func unlock():
	set_visible(true)
	
func _show_popup():
	var popup = popup_scene.instantiate()
	popup.set_item_buy(item)
	get_tree().current_scene.find_child("HUD", true).add_child(popup) 
	
