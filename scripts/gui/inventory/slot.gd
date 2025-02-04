extends Panel

@onready var item_sprite: Sprite2D = $ItemContainer/ItemPanel/Item
@onready var stack_number: Label = $ItemContainer/ItemPanel/Stack

func update(slot: Slot):
	if !slot.item:
		item_sprite.visible = false
		stack_number.visible = false
	else:
		item_sprite.visible = true
		item_sprite.texture = slot.item.texture
		if slot.stack_size > 0:
			stack_number.visible = true
			stack_number.text = str(slot.stack_size)