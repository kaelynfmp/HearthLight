extends Control
var game_time = GameManager.game_time
@export var day_label: RichTextLabel 
@export var time_label: RichTextLabel
var initial_position
var current_minute = 0

func _ready():
	set_process(true)
	modulate.a = 1
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
		position.y = 20
		
	else:
		position = initial_position
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	if game_time["hour"] > GameManager.continue_clock_in_computer:
		if modulate.a >0.5:
			modulate.a -= 0.005
		elif modulate.a <= 0.5 and current_minute != game_time["minute"]:
			modulate.a = 1
			current_minute = game_time["minute"]
	else:
		modulate.a = 1
