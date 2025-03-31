extends Control
var game_time = GameManager.game_time
@export var day_label: RichTextLabel 
@export var time_label: RichTextLabel
var initial_position

func _ready():
	set_process(true)
	initial_position = position

func _process(_delta: float) -> void:
	day_label.text = "Day "+ str(game_time["day"])
	if str(game_time["minute"]).length() == 1:
		time_label.text = str(game_time["hour"])+":"+"0"+str(game_time["minute"])
	else:
		time_label.text = str(game_time["hour"])+":"+str(game_time["minute"])
	
	if GameManager.in_computer:
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		position.y = 0
		
	else:
		position = initial_position
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
