extends VBoxContainer

@export var slide_in_speed:float
@export var teleporter:Gadget

var starting_x:float
var max_pos:float

func _ready() -> void:
	starting_x = position.x
	max_pos = get_viewport_rect().size.x + (size.x * scale.x) + 10
	set_position(Vector2(max_pos, position.y))

func _process(delta: float) -> void:
	set_position(Vector2(lerp(position.x, starting_x 
	if GameManager.inventory and (GameManager.gadget == null or GameManager.gadget.gadget_stats != teleporter)
	else max_pos, slide_in_speed * delta), position.y))
