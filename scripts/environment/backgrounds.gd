extends Node2D

@export var backgrounds:Array[ParallaxBackground]
var time_per_background:float

func _ready() -> void:
	GameManager.awaken.connect(reset_backgrounds)
	time_per_background = GameManager.max_time / float(backgrounds.size())

func _process(_delta: float):
	var time_in_day:int = GameManager.active_time * GameManager.time_scale
	
	var current_background_index = floor(time_in_day / time_per_background)
	if current_background_index < backgrounds.size() - 1:
		var current_background:ParallaxBackground = backgrounds[current_background_index]
		var alpha:float = abs(((time_in_day % roundi(time_per_background)) - time_per_background)/time_per_background)
		for layer:ParallaxLayer in current_background.get_children():
			layer.modulate.a = alpha
		
	
func reset_backgrounds():
	for background:ParallaxBackground in backgrounds:
		for layer:ParallaxLayer in background.get_children():
			layer.modulate.a = 1.0
