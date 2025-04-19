# player.gd
extends "res://scripts/Optimization/Interpolate.gd"

@export var max_health: int = 1000
@export var rising_gravity_multiplier: float = 2.2
@export var falling_gravity_multiplier: float = 2.2
@export var knockback_power: float = 1200
@export var onair_knockback_power: float = 750
@export var projectile_scene: PackedScene = preload("res://scene/projectile.tscn")

@onready var visuals: Node2D = $Node2D as Node2D
@onready var main: AnimatedSprite2D = visuals.get_node("CharacterSprite2D") as AnimatedSprite2D
@onready var wep: Node2D = visuals.get_node("WeaponSprite2D") as Node2D
@onready var proj_marker: Marker2D = visuals.get_node("WeaponSprite2D/Marker2D") as Marker2D

@onready var cayote_timer: Timer = $CayoteTimer as Timer
@onready var jumpbuffer_timer: Timer = $JumpBufferTimer as Timer
@onready var JumpHang_Timer: Timer = $JumpHangTimer as Timer
@onready var NoDamage_Timer: Timer = $NoDamageTimer as Timer
@onready var current_health: int = max_health

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float
var jump_active: bool = false
var was_on_floor: bool = true

const JUMP_VELOCITY: float = -975.0
const TOP_SPEED: float = 600.0
const ACCELERATION: float = 3000.0
const DECELERATION: float = 3000.0
var speed_multiplier: float = 1.0

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position
	add_to_group("player")

func _physics_process(delta: float) -> void:
	previous_position = global_position
	var mouse_pos: Vector2 = get_global_mouse_position()

	if not is_on_floor():
		if velocity.y < 0.0:
			var rise_mul: float = 1.0
			if not JumpHang_Timer.is_stopped():
				rise_mul = rising_gravity_multiplier
			velocity.y += gravity * rise_mul * delta
		else:
			velocity.y += gravity * falling_gravity_multiplier * delta
	else:
		if not JumpHang_Timer.is_stopped():
			JumpHang_Timer.stop()

	if jump_active and velocity.y >= 0.0:
		jump_active = false

	# Coyote time
	if is_on_floor():
		was_on_floor = true
		if not cayote_timer.is_stopped():
			cayote_timer.stop()
	else:
		if was_on_floor:
			cayote_timer.start()
			was_on_floor = false

	# Jump input
	if Input.is_action_just_pressed("jump"):
		if (is_on_floor() or not cayote_timer.is_stopped()) and not jump_active:
			velocity.y = JUMP_VELOCITY
			JumpHang_Timer.start()
			cayote_timer.stop()
			jumpbuffer_timer.stop()
			jump_active = true
		elif jumpbuffer_timer.is_stopped():
			jumpbuffer_timer.start()

	if is_on_floor() and not jumpbuffer_timer.is_stopped() and not jump_active:
		velocity.y = JUMP_VELOCITY
		JumpHang_Timer.start()
		jumpbuffer_timer.stop()
		jump_active = true

	# Horizontal movement
	var direction: float = Input.get_axis("left", "right")
	var accel: float
	if direction != 0.0:
		accel = ACCELERATION
	else:
		accel = DECELERATION
	velocity.x = move_toward(velocity.x, direction * TOP_SPEED * speed_multiplier, accel * delta)

	# Play animations
	if direction != 0.0:
		main.play("run")
	else:
		main.play("iddle")

	# Facing direction
	if mouse_pos.x < global_position.x:
		visuals.scale.x = -1.0
	else:
		visuals.scale.x = 1.0

	# Weapon aim
	var local_mouse: Vector2 = visuals.to_local(mouse_pos)
	wep.rotation = clamp(local_mouse.angle(), deg_to_rad(-50.0), deg_to_rad(50.0))

	# Shooting
	if Input.is_action_pressed("Shoot"):
		Projectile.shoot(proj_marker.global_position, mouse_pos, projectile_scene, self)

	move_and_slide()

func take_damage(amount: int, enemy_Velocity: Vector2 = Vector2.ZERO) -> void:
	if NoDamage_Timer.is_stopped():
		current_health = max(current_health - amount, 0)
		update_health_bar()
		NoDamage_Timer.start()
		if enemy_Velocity != Vector2.ZERO:
			knockback(enemy_Velocity)
		if current_health <= 0:
			die()

func die() -> void:
	current_health = max_health
	update_health_bar()

func update_health_bar() -> void:
	var hp_bar_node: Node = get_tree().get_first_node_in_group("playerHP")
	if hp_bar_node:
		var hp_bar: ProgressBar = hp_bar_node.get_node("ProgressBar_health") as ProgressBar
		var timer: Timer = hp_bar_node.get_node("Timer") as Timer
		hp_bar.value = float(current_health) / float(max_health) * 100.0
		timer.start()

func knockback(enemy_Velocity: Vector2) -> void:
	var current_knockback: float = knockback_power if is_on_floor() else onair_knockback_power
	var knock_dir: Vector2 = (enemy_Velocity - velocity).normalized() * current_knockback
	velocity = knock_dir
	move_and_slide()

func apply_slow(multiplier: float) -> void:
	speed_multiplier = multiplier

func reset_speed() -> void:
	speed_multiplier = 1.0
