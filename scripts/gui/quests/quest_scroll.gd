extends ScrollContainer

var prev_state = GameManager.quest_list_visible
var max_height:float = 0.0
var max_possible_height:float
var prev_max_height:float
@export_enum("Linear", "Sine", "Quint", "Quart", "Quad", "Expo", "Elastic", "Cubic", "Circ", "Bounce", "Back") var transition:int = Tween.TRANS_CUBIC
@export var transition_time:float = 1.0

func _ready() -> void:
	max_possible_height = size.y

func _process(_delta: float) -> void:
	max_height = min($QuestList.size.y + 1, max_possible_height)
	# Only scrollable if fully expanded
	if size.y == max_height:
		vertical_scroll_mode = SCROLL_MODE_AUTO
	else:
		vertical_scroll_mode = SCROLL_MODE_SHOW_NEVER

	if GameManager.quest_list_visible != prev_state:
		prev_state = GameManager.quest_list_visible
		# If state is changed, play the animation to slide in or out
		if GameManager.quest_list_visible:
			expand()
		else:
			shrink()
	elif prev_max_height != max_height:
		if prev_max_height < max_height:
			expand()
		else:
			shrink(max_height)
		prev_max_height = max_height
			
func expand():
	var tween:Tween = get_tree().create_tween()
	tween.tween_property(self, "size", Vector2(size.x, max_height), transition_time).set_trans(transition)
	
func shrink(_size:float = 0.0):
	var tween:Tween = get_tree().create_tween()
	tween.tween_property(self, "size", Vector2(size.x, _size), transition_time).set_trans(transition)
