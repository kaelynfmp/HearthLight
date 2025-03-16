@tool
extends PanelContainer

@export var slot: Slot

@onready var tooltip_control:Control = find_child("TooltipControl")
@onready var tooltip:RichTextLabel = find_child("Tooltip", true)
@onready var title:RichTextLabel = find_child("Title", true)
@onready var tooltip_image:TextureRect = find_child("TooltipImage", true)

var mouse_over: bool = false
## If you are currently holding right click to make a 'line'
var rmb_line: bool = false
## If your current mouse input involved attempting to pull out a half stack
var just_half_stacked: bool = false

var hover_timer:float = 0.0
var hover_time:float = 0.7 # in seconds
var fade_time:float = 0.05 # in seconds

func _ready():
	tooltip_control.set_modulate(Color(1, 1, 1, 0))

func _process(delta: float) -> void:
	if slot != null:
		tooltip_control.visible = slot.item != null
		tooltip_control.set_position(get_local_mouse_position() + Vector2(50, 50))
		if slot.item != null:
			tooltip_image.set_texture(slot.item.texture)
			tooltip.set_text(slot.item.description)
			title.set_text(slot.item.name)
		if mouse_over and slot.item != null:
			var change_rate:float = delta / hover_time
			hover_timer += change_rate
			hover_timer = clamp(hover_timer, 0, 1.0)
			if hover_timer >= 1.0:
				tooltip_control.set_modulate(Color(1, 1, 1, lerp(tooltip_control.get_modulate().a, 1.0, delta / fade_time)))
		else:
			hover_timer = 0
			tooltip_control.set_modulate(Color(1, 1, 1, lerp(tooltip_control.get_modulate().a, 0.0, delta / fade_time)))

func update():
	var item_sprite:TextureRect = find_child("Item", true)
	var stack_number:Label = find_child("Stack", true)
	if slot != null:
		if !slot.item:
			item_sprite.visible = false
			stack_number.visible = false
		else:
			item_sprite.visible = true
			item_sprite.set_texture(slot.item.texture)
			if slot.quantity > 1:
				stack_number.visible = true
				stack_number.text = str(slot.quantity)
			else:
				stack_number.visible = false
	else:
		item_sprite.visible = false
		stack_number.visible = false

## On mouse entered, it will check to see if it can distribute slots, pick up slotsor if it can start placing with
## right click
func _on_mouse_entered() -> void:
	mouse_over = true
	if cursor_slot() == null:
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if Input.is_action_pressed("modifier"):
			GameManager.send_to_inventory(slot)
		else:
			if cursor_slot().item == null:
				# Distribute
				if slot.item == null:
					GameManager.append_slot_distributor(slot)
				elif slot.item == GameManager.slot_distributor.item:
					GameManager.append_slot_distributor(slot, slot.quantity)
			elif cursor_slot().item == slot.item:
				# Absorb item
				slot.initialize(cursor_slot().item, cursor_slot().increment(slot.quantity))
		# If the cursor slot can't fit it, the slot will keep whatever remains

	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# slide to add one
		drop_slot_cursor()
		rmb_line = true

## On mouse exit, it will add to the original slot if dragged off from right click for distribution purposes
func _on_mouse_exited() -> void:
	mouse_over = false
	if cursor_slot() == null:
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and !rmb_line:
		# Will add one to the original slot if dragged off
		drop_slot_cursor()

## On click, do inventory management
func _on_gui_input(event:InputEvent) -> void:
	if cursor_slot() == null:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# If the items arent both null, OR if you left click, swap the items
			if event.is_pressed():
				if Input.is_action_pressed("modifier"):
					GameManager.send_to_inventory(slot)
					pass
				else:
					if cursor_slot().item != null and slot.item == null:
						GameManager.initialize_slot_distributor(cursor_slot().quantity, cursor_slot().item)
						if GameManager.append_slot_distributor(slot):
							cursor_slot().item = null
					elif cursor_slot().item != null or slot.item != null:
						swap_slots_cursor()
			else:
				GameManager.clear_slot_distributor()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			rmb_line = false
			# Since we previously check to see that the item slot isn't swappable, this will always work
			if event.is_pressed():
				just_half_stacked = true
				half_slot_cursor_pickup() # Try to pick up half, which will drop 1 item if it cant
			else:
				if mouse_over:
					# The mouse needs to still be on the slot for it to want to drop it
					drop_slot_cursor()
				just_half_stacked = false # On release of right click, after trying to drop the first time
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Wheel up adds items
			if event.is_pressed():
				drop_slot_cursor(true)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Wheel down takes
			if event.is_pressed():
				pull_slot_cursor(true)

## Swap the current slot with the cursor slot
func swap_slots_cursor(bypass: bool = false):
	if slot.item != cursor_slot().item or bypass:
		if slot.can_insert(cursor_slot().item):
			var temp_item: Item    = cursor_slot().item
			var temp_quantity: int = cursor_slot().quantity
			cursor_slot().initialize(slot.item, slot.quantity)
			slot.initialize(temp_item, temp_quantity)
	else:
		merge_slots_cursor()

## Merge the current slot with the cursor slot
func merge_slots_cursor() -> void:
	if slot.item == cursor_slot().item:
		if not slot.can_insert(slot.item):
			var remainder: int = cursor_slot().increment(slot.quantity)
			slot.decrement(slot.quantity - remainder)
		else:
			var remainder: int = slot.increment(cursor_slot().quantity)
			if remainder == cursor_slot().quantity:
				# Just swap if you're trying to touch something that's full
				swap_slots_cursor(true)
				return
			cursor_slot().decrement(cursor_slot().quantity - remainder)
	else:
		swap_slots_cursor()

## Drop one item from cursor into slot
func drop_slot_cursor(bypass: bool = false) -> void:
	if (just_half_stacked and not bypass):
		return
	if cursor_slot().item != null and (slot.item == null or slot.item == cursor_slot().item):
		if not slot.can_insert(cursor_slot().item):
			var remainder: int = cursor_slot().increment(slot.quantity)
			slot.decrement(1 - remainder)
		else:
			# If there is an item on your cursor when you click, place exactly one into the slot
			# It also ensures that the slot is either empty or populated with something stackable
			if (slot.initialize(cursor_slot().item, slot.quantity + 1) == 0): # No remainder
				# We initialize here instead of incrementing becasue we need to ensure the item is correct if it's empty
				# If the stack isn't maxed, put one in
				cursor_slot().decrement()

## Take one item from slot into cursor
func pull_slot_cursor(bypass: bool = false) -> void:
	if (just_half_stacked and not bypass):
		return
	if cursor_slot().item == null or (cursor_slot().item == slot.item and not slot.item == null):
		# If you either have nothing, or have the item you're trying to take (and it exists)
		if (cursor_slot().initialize(slot.item, cursor_slot().quantity + 1) == 0): # No remainder
			# We initialize here instead of incrementing becasue we need to ensure the item is correct if it's empty
			slot.decrement()


## Pick up half of the stack in the slot
func half_slot_cursor_pickup() -> void:
	if cursor_slot().item != null and slot.item != cursor_slot().item:
		if slot.item == null:
			# If it's nothing, do nothing to prepare for the drop later
			just_half_stacked = false
			return
		swap_slots_cursor()
		return
	if slot.item != null and cursor_slot().item == null:
		if slot.quantity < 2:
			swap_slots_cursor() # It's just a 1-to-1 swap
		else:
			var temp_quantity: float = float(slot.quantity)
			slot.decrement(ceil(temp_quantity/2))
			# There hopefully shouldn't ever possibly be a remainder condition but, just in case
			var remainder: int = cursor_slot().initialize(slot.item, ceil(temp_quantity/2))
			slot.increment(remainder)
	else:
		just_half_stacked = false

## Returns the globally defined slot that belongs to the cursor
func cursor_slot() -> Slot:
	if "cursor" in GameManager:
		# This wouldn't be true if this is being done in the editor
		return GameManager.cursor.slot
	return null

func set_slot(setting_slot: Slot):
	if slot:
		if slot.changed.is_connected(update):
			slot.changed.disconnect(update)
	slot = setting_slot
	if slot != null:
		slot.changed.connect(update)
	update()
