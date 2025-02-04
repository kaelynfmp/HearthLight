extends CharacterBody2D

const SPEED:int = 1000

## The [Inventory] containing all of the players items.
@export var inventory : Inventory

@onready var anim_tree:Node = get_node("AnimationTree")

func _process(_delta: float) -> void:
	for sprite:AnimatedSprite2D in $Sprite.get_children():
		if velocity == Vector2.ZERO: continue
		if round(abs(rad_to_deg(velocity.angle()))) == 90: continue
		if sign(cos(velocity.angle())) == -1:
			sprite.flip_h = true;
		elif sign(cos(velocity.angle())) == 1:
			sprite.flip_h = false;

	if self.velocity == Vector2.ZERO:
		anim_tree.get("parameters/playback").travel("Idle")
	else:
		anim_tree.get("parameters/playback").travel("Walk")

func _physics_process(_delta: float) -> void:
	var direction:Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		self.velocity = direction * SPEED;
	else:
		self.velocity = Vector2.ZERO

	move_and_slide()
	
	# TEMP
	if Input.is_action_just_pressed("ui_accept"):
		var item: Item = load("res://resources/items/cotton.tres")
		collect(item)
		
## 'Collects' a given item, placing it into the inventory on the nearest open slot
func collect(item: Item):
	inventory.insert(item)
