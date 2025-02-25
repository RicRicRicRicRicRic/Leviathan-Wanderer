extends CharacterBody2D 

@onready var visuals = $Node2D
@onready var char = visuals.get_node("CharacterSprite2D")
@onready var wep = visuals.get_node("WeaponSprite2D")

const SPEED = 500.0
const JUMP_VELOCITY = -600.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()

	# --- Movement Setup ---
	if not is_on_floor():
		velocity.y += gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# --- Animation ---
	if direction != 0:
		char.play("run")
	else:
		char.play("iddle")
	
	# --- Flip Visuals Based on Mouse Position ---
	var facing_left = mouse_pos.x < global_position.x
	if facing_left:
		visuals.scale.x = -1
	else:
		visuals.scale.x = 1

	# --- Weapon Aiming in Visuals' Local Space ---
	var local_mouse = visuals.to_local(mouse_pos)
	var aim_angle = local_mouse.angle()
	aim_angle = clamp(aim_angle, deg_to_rad(-50), deg_to_rad(50))
	wep.rotation = aim_angle

	move_and_slide()
