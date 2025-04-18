extends Panel
@export var given_container:VBoxContainer
@export var given_grid: HFlowContainer
@export var given_label: RichTextLabel
@export var needed_container:VBoxContainer
@export var needed_grid: HFlowContainer
@export var needed_label: RichTextLabel
@export var reward_container:VBoxContainer
@export var reward_grid: HFlowContainer
@export var rewards_label: RichTextLabel
@export var currency_container:VBoxContainer
@export var currency_label: Label
@export var unlock_icon: TextureRect
@export var grid_scene: PackedScene

@export var given_grid_bg: Texture2D
@export var needed_grid_bg: Texture2D
@export var rewarded_grid_bg: Texture2D
var order: Order

#var email = email_button.email
func _ready() -> void:
	var panel = get_parent()
	var email_button = panel.get_parent()
	var email = email_button.email
	if email and email.attached_order:
		order = email.attached_order
		adjust_size()
		populate_order_hint(given_container, given_grid, order.given_items, order.given_quantities)
		populate_order_hint(needed_container, needed_grid, order.required_items, order.required_quantities)
		populate_order_hint(reward_container, reward_grid, order.rewards, order.rewards_quantities)
		if not order.unlocks.is_empty() or order.currency_reward > 0:
			show_currency_reward()
			show_unlock_icon()
	else:
		visible = false

func _process(delta: float) -> void:
	pass

func adjust_size():
	if len(order.given_items) > 2 or len(order.required_items) > 2 or len(order.rewards)>2:
		custom_minimum_size =Vector2(1920, 525)

func populate_order_hint(container: VBoxContainer, grid: HFlowContainer, item_list: Array, item_quantities: Array):
	if item_list.is_empty():
		container.visible = false
	for item in item_list:
		if item is Gadget:
			item = item.item # if item is a gadget, get its corresponding item
		if item is Item:
			var item_display = grid_scene.instantiate()
			var item_texture = item_display.get_node("ItemTexture")
			item_texture.texture = item.texture
			
			var item_quantity_label = item_display.get_node("ItemQuantityLabel")
			var index = item_list.find(item)
			item_quantity_label.text = str(item_quantities[index])
			
			# default is given grid bg
			var center_x = grid.position.x #+ grid.size.x / 2
			if grid == needed_grid:
				item_display.texture = needed_grid_bg
				needed_label.position.x = center_x
			elif grid == reward_grid:
				item_display.texture = rewarded_grid_bg
			else:
				given_label.position.x = center_x
			#if len(item_list) == 3:
				#var blank_tile := Control.new()
				#blank_tile.custom_minimum_size = Vector2(0,0)
				#grid.add_child(blank_tile)
			grid.add_child(item_display)

func show_currency_reward():
	currency_label.text = str(order.currency_reward)
	if order.currency_reward <= 0:
		currency_label.modulate.a = 0.2

func show_unlock_icon():
	if len(order.unlocks)>0:
		unlock_icon.modulate.a = 1
	else:
		unlock_icon.modulate.a = 0.2
