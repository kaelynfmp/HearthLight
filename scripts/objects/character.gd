extends CharacterBody2D

const SPEED:int = 1000

## The [Inventory] containing all of the players items.
@export var inventory : Inventory

@export var camera_edges:Array[int]
@export var inventory_camera_offset:float

@onready var camera:Camera2D = get_node("Camera")

@onready var anim_tree:Node = get_node("AnimationTree")

func _ready() -> void:
	GameManager.player_inventory = inventory

func _process(_delta: float) -> void:
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
		camera_position = GameManager.gadget.position
		camera_position.x += inventory_camera_offset / 2
		camera_position.y += 540 - 32 # Buffer to make it look more centered
	camera.set_global_position(camera_position)
	for sprite:AnimatedSprite2D in $Sprite.get_children():
		if velocity == Vector2.ZERO: continue
		if round(abs(rad_to_deg(velocity.angle()))) == 90: continue
		if sign(cos(velocity.angle())) == -1:
			sprite.flip_h = false;
		elif sign(cos(velocity.angle())) == 1:
			sprite.flip_h = true;

	if self.velocity == Vector2.ZERO or GameManager.sleeping:
		anim_tree.get("parameters/playback").travel("Idle")
	else:
		anim_tree.get("parameters/playback").travel("Walk")

func _physics_process(_delta: float) -> void:
	if !GameManager.computer_visible and !GameManager.sleeping:
		var direction:Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction:
			self.velocity = direction * SPEED;
		else:
			self.velocity = Vector2.ZERO
	
		move_and_slide()
	
## 'Collects' a given item, placing it into the inventory on the nearest open slot
func collect(item: Item):
	inventory.insert(item)
