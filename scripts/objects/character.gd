extends CharacterBody2D

const SPEED:int = 1000

@onready var anim_tree:Node = get_node("AnimationTree")

func _process(delta: float) -> void:

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

	pass

func _physics_process(delta: float) -> void:
	var direction:Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		self.velocity = direction * SPEED;
	else:
		self.velocity = Vector2.ZERO

	move_and_slide()


	
