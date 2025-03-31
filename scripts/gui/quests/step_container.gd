extends MarginContainer

var required_item:Item
var required_quantity:int
var fulfilled_quantity:int

func _ready():
	set_item_text()
		
func _process(_delta: float) -> void:
	if GameManager.quest_list_visible:
		# No need to do any of this if the quest list isn't even visible to begin with
		fulfilled_quantity = min(GameManager.player_inventory.get_item_quantity(required_item), required_quantity)
		set_item_text()
		if fulfilled_quantity < required_quantity:
			$Step/CompletionIcon.modulate = Color(1, 1, 1, 0)
		else:
			$Step/CompletionIcon.modulate = Color(1, 1, 1, 1)
	
func set_item_text():
	if required_item:
		var text:String = ""
		text += "[res=" + required_item.name + "] " + (required_item.name if fulfilled_quantity < required_quantity else "[s][i]" + required_item.name + "[/i][/s]") + "[/res]"
		if required_quantity:
			text += ": " + str(fulfilled_quantity) + "/"
			text += str(required_quantity)
		$Step/StepText.set_text_with_bbcode(text)
