extends Control
var game_time = GameManager.game_time
@export var day_label: RichTextLabel 
@export var time_label: RichTextLabel
var initial_position
var day_initial
var time_initial
var current_minute = 0

func _ready():
	set_process(true)
	modulate.a = 1
	initial_position = position
	day_initial = day_label.position
	time_initial = time_label.position

func _process(_delta: float) -> void:
	day_label.text = "Day "+ str(game_time["day"])
	if str(game_time["minute"]).length() == 1:
		time_label.text = str(game_time["hour"])+":"+"0"+str(game_time["minute"])
	else:
		time_label.text = str(game_time["hour"])+":"+str(game_time["minute"])
	
	if GameManager.in_computer:
		anchor_left = 0.5
		anchor_right = 0.5
		set_anchors_preset(Control.PRESET_CENTER_TOP)
		position.x = 900  # Moves it left by half its width
		
	else:
		position = initial_position  
		day_label.set_position(day_initial)
		time_label.set_position(time_initial)
	
	if game_time["hour"] > GameManager.continue_clock_in_computer:
		if modulate.a >0.5:
			modulate.a -= 0.005
		elif modulate.a <= 0.5 and current_minute != game_time["minute"]:
			modulate.a = 1
			current_minute = game_time["minute"]
	else:
		modulate.a = 1
