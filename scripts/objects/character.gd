extends CharacterBody2D

class_name Character

signal camera_moved

const SPEED:int = 1000

## The [Inventory] containing all of the players items.
@export var inventory : Inventory

@export var camera_edges:Array[int]
@export var inventory_camera_offset:float

@onready var camera:Camera2D = get_node("Camera")

@onready var anim_tree:Node = get_node("AnimationTree")

@onready var footsteps_audio:AudioStreamPlayer2D = get_node("Footsteps")

var prev_camera_position:Vector2

var left:bool = true

func _ready() -> void:
	GameManager.player_inventory = inventory
	GameManager.character = self
	
func _process(_delta: float) -> void:
	if GameManager.cutscene_displayed:
		return
	inventory_camera_offset = 3000 if position.x > 2000 else 1000
	var camera_position:Vector2 = Vector2(
		clamp(position.x + (inventory_camera_offset if GameManager.inventory else 0.0),
		camera_edges[0] + (inventory_camera_offset if GameManager.inventory else 0.0),
		camera_edges[2] + (inventory_camera_offset if GameManager.inventory else 0.0)),
		clamp(position.y,
		camera_edges[1],
		camera_edges[3]))
	if GameManager.gadget != null:
		# Center on gadget if gadget selected
		if GameManager.gadget.gadget_stats.name == "Teleporter" and not (GameManager.cursor != null and GameManager.cursor.slot.item != null):
			camera_position = Vector2(0, 0)
		else:
			camera_position = GameManager.gadget.position
			camera_position.x += inventory_camera_offset / 2
			camera_position.y = clamp(camera_position.y + 540 - 32, camera_edges[1], camera_edges[3]) # Buffer to make it look more centered
			# y values are still clamped because of screen edge shenanigans
	camera.set_global_position(camera_position)
	for sprite:AnimatedSprite2D in $Sprite.get_children():
		if velocity == Vector2.ZERO: continue
		if round(abs(rad_to_deg(velocity.angle()))) == 90: continue
		if sign(cos(velocity.angle())) == -1:
			left = true
		elif sign(cos(velocity.angle())) == 1:
			left = false

	if self.velocity == Vector2.ZERO or GameManager.sleeping:
		anim_tree.get("parameters/playback").travel("Idle")
		if footsteps_audio.playing:
			footsteps_audio.stop()
	else:
		if left:
			anim_tree.get("parameters/playback").travel("WalkLeft")
		else:
			anim_tree.get("parameters/playback").travel("WalkRight")
		if not footsteps_audio.playing:
			footsteps_audio.play()
		elif GameManager.in_computer:
			footsteps_audio.stop()

func _physics_process(_delta: float) -> void:
	if !GameManager.computer_visible and !GameManager.sleeping:
		var direction:Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction:
			self.velocity = direction * SPEED;
		else:
			self.velocity = Vector2.ZERO
	
		move_and_slide() 
	if camera.get_screen_center_position() != prev_camera_position:
		prev_camera_position = camera.get_screen_center_position()
		camera_moved.emit()
	
## 'Collects' a given item, placing it into the inventory on the nearest open slot
func collect(item: Item):
	inventory.insert(item)
