extends Control
var game_time = GameManager.game_time
@export var day_label: RichTextLabel 
@export var time_label: RichTextLabel

func _ready():
	set_process(true) 

func _process(_delta: float) -> void:
	day_label.text = "Day "+ str(game_time["day"])
	if str(game_time["minute"]).length() == 1:
		time_label.text = str(game_time["hour"])+":"+"0"+str(game_time["minute"])
	else:
		time_label.text = str(game_time["hour"])+":"+str(game_time["minute"])
