extends Panel

@onready var item_sprite: Sprite2D = $ItemContainer/ItemPanel/Item
@onready var stack_number: Label = $ItemContainer/ItemPanel/Stack

var slot: Slot

var mouse_over = false
### If you are currently holding right click to make a 'line'
var rmb_line = false
### If your current mouse input involved attempting to pull out a half stack
var just_half_stacked = false

func update():
	if slot != null:
		if !slot.item:
			item_sprite.visible = false
			stack_number.visible = false
		else:
			item_sprite.visible = true
			item_sprite.texture = slot.item.texture
			if slot.quantity > 1:
				stack_number.visible = true
				stack_number.text = str(slot.quantity)
			else:
				stack_number.visible = false
	else:
		item_sprite.visible = false
		stack_number.visible = false

func _on_mouse_entered() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# slide to add one
		drop_slot_cursor()
		rmb_line = true
	mouse_over = true
	
func _on_mouse_exited() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and !rmb_line:
		# Will add one to the original slot if dragged off
		drop_slot_cursor()
	mouse_over = false
	
### On click, do inventory management
func _on_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			# If the items arent both null, OR if you left click, swap the items
			if cursor_slot().item != null or slot.item != null:
				swap_slots_cursor()
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
				
### Swap the current slot with the cursor slot
func swap_slots_cursor():
	if slot.item != cursor_slot().item:
		var temp_item: Item    = cursor_slot().item
		var temp_quantity: int = cursor_slot().quantity
		cursor_slot().initialize(slot.item, slot.quantity)
		slot.initialize(temp_item, temp_quantity)
		update()
		GameManager.get_cursor().update_slot()
	else:
		merge_slots_cursor()
	
### Merge the current slot with the cursor slot
func merge_slots_cursor():
	if slot.item == cursor_slot().item:
		var remainder: int = slot.increment(cursor_slot().quantity)
		cursor_slot().decrement(cursor_slot().quantity - remainder)
		update()
		GameManager.get_cursor().update_slot()
	else:
		swap_slots_cursor()
	
### Drop one item from cursor into slot
func drop_slot_cursor():
	if (just_half_stacked):
		return
	if cursor_slot().item != null and (slot.item == null or slot.item == cursor_slot().item):
		# If there is an item on your cursor when, place exactly one into the slot
		# It also ensures that the slot is either empty or populated with something stackable
		slot.item = cursor_slot().item # It will always either be empty or the item already anyways
		if (slot.increment() == 0): # No remainder
		# If the stack isn't maxed, put one in
			cursor_slot().decrement()
		update()
		GameManager.get_cursor().update_slot()
		
### Pick up half of the stack in the slot
func half_slot_cursor_pickup():
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
			cursor_slot().item = slot.item
			# There hopefully shouldn't ever possibly be a remainder condition but, just in case
			var remainder: int = cursor_slot().increment(floor(temp_quantity/2))
			slot.increment(remainder)
			update()
			GameManager.get_cursor().update_slot()
	else:
		just_half_stacked = false
		
### Returns the globally defined slot that belongs to the cursor
func cursor_slot() -> Slot:
	return GameManager.get_cursor().get_slot()
			
func set_slot(setting_slot: Slot):
	slot = setting_slot
	update()

func get_slot():
	return slot
