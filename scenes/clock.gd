extends Control
var game_time = GameManager.game_time
@export var day_label: RichTextLabel 
@export var time_label: RichTextLabel
var initial_position
var day_label_initial_position
var current_minute = 0

func _ready():
	set_process(true)
	modulate.a = 1
	initial_position = position
	day_label_initial_position = day_label.position

func _process(_delta: float) -> void:
	day_label.text = "Day "+ str(game_time["day"])
	if str(game_time["minute"]).length() == 1:
		time_label.text = str(game_time["hour"])+":"+"0"+str(game_time["minute"])
	else:
		time_label.text = str(game_time["hour"])+":"+str(game_time["minute"])
	
	if GameManager.in_computer:
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		position.y = -38
		position.x = 60
		day_label.position.y = 60
		if game_time["day"] < GameManager.debt_days - 1:
			day_label.text = str(GameManager.debt_days - game_time["day"]) + " Days to Pay Debt"
		elif game_time["day"] < GameManager.debt_days:
			day_label.text = str(GameManager.debt_days - game_time["day"]) + " Day to Pay Debt"
		elif game_time["day"] == GameManager.debt_days:
			day_label.text = "Final Day to Pay Debt"
			day_label.modulate = Color(0.5, 0, 0)
			
	else:
		position = initial_position
		day_label.position = day_label_initial_position
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	if GameManager.time_final:
		if modulate.a >0.5:
			modulate.a -= 0.005
		elif modulate.a <= 0.5 and current_minute != game_time["minute"]:
			modulate.a = 1
			current_minute = game_time["minute"]
	else:
		modulate.a = 1
