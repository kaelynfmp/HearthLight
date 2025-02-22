extends StaticBody2D

@onready var gadget_stats = load("res://resources/gadgets/wheel.tres")

@export var output_inventory: Inventory

var character: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	character = get_parent().get_parent().get_parent().find_child("Character")
	$Sprite2D.texture = gadget_stats.texture
	$Timer.wait_time = gadget_stats.process_time
	$Timer.start()
	$Timer.timeout.connect(add_item_to_inventory)
	$TextureProgressBar.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$TextureProgressBar.value = 100 - ($Timer.time_left / $Timer.wait_time) * 100
	
func add_item_to_inventory() -> void:
	var item: Item = load("res://resources/items/cotton.tres")
	collect(item)
		
## 'Collects' a given item, placing it into the inventory on the nearest open slot
func collect(item: Item):
	character.inventory.insert(item)
