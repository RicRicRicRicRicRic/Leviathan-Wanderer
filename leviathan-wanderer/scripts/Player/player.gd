# player.gd
extends "res://scripts/Optimization/Interpolate.gd"

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position

# --- onready visuals ---
@onready var visuals: Node2D = $Node2D
@onready var main: AnimatedSprite2D = visuals.get_node("CharacterSprite2D") as AnimatedSprite2D
@onready var wep: Node2D = visuals.get_node("WeaponSprite2D") as Node2D
@onready var marker: Marker2D = visuals.get_node("WeaponSprite2D/Marker2D") as Marker2D

# --- Movement mechanics ---
@onready var cayote_timer: Timer = $CayoteTimer
@onready var jumpbuffer_timer: Timer = $JumpBufferTImer
var was_on_floor: bool = true

const SPEED: float = 500.0
const JUMP_VELOCITY: float = -600.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float

@export var projectile_scene: PackedScene = preload("res://scene/projectile.tscn")

func _physics_process(delta: float) -> void:
	previous_position = global_position
	var mouse_pos: Vector2 = get_global_mouse_position()

	# --- Gravity ---
	if not is_on_floor():
		velocity.y += gravity * delta

	# --- Coyote Time ---
	if is_on_floor():
		was_on_floor = true
		if not cayote_timer.is_stopped():
			cayote_timer.stop()
	else:
		if was_on_floor:
			cayote_timer.start()
			was_on_floor = false

	# --- Jumping (Normal, Coyote, and Jump Buffer) ---
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or (not cayote_timer.is_stopped()):
			velocity.y = JUMP_VELOCITY
			cayote_timer.stop()
			# If a jump is performed immediately, clear any buffered jump.
			jumpbuffer_timer.stop()
		else:
			# Buffer the jump input if jump isn't immediately allowed.
			if jumpbuffer_timer.is_stopped():
				jumpbuffer_timer.start()

	# If the player lands and a jump was buffered, perform the jump.
	if is_on_floor() and not jumpbuffer_timer.is_stopped():
		velocity.y = JUMP_VELOCITY
		jumpbuffer_timer.stop()

	# --- Horizontal Movement ---
	var direction: float = Input.get_axis("left", "right")
	velocity.x = direction * SPEED if direction != 0.0 else move_toward(velocity.x, 0.0, SPEED)

	# --- Animation ---
	main.play("run" if direction != 0.0 else "iddle")

	# --- Flip Visuals Based on Mouse Position ---
	visuals.scale.x = -1.0 if mouse_pos.x < global_position.x else 1.0

	# --- Weapon Aiming ---
	var local_mouse: Vector2 = visuals.to_local(mouse_pos)
	var aim_angle: float = clamp(local_mouse.angle(), deg_to_rad(-50.0), deg_to_rad(50.0))
	wep.rotation = aim_angle

	# --- Shooting ---
	if Input.is_action_pressed("Shoot"):
		Projectile.shoot(marker.global_position, mouse_pos, projectile_scene, self)

	move_and_slide()
