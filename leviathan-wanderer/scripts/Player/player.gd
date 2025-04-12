# player.gd
extends "res://scripts/Optimization/Interpolate.gd"

@export var max_health: int = 1000
@export var rising_gravity_multiplier: float = 2.2
@export var falling_gravity_multiplier: float = 2.2
@export var projectile_scene: PackedScene = preload("res://scene/projectile.tscn")

@onready var visuals: Node2D = $Node2D
@onready var main: AnimatedSprite2D = visuals.get_node("CharacterSprite2D") as AnimatedSprite2D
@onready var wep: Node2D = visuals.get_node("WeaponSprite2D") as Node2D
@onready var proj_marker: Marker2D = visuals.get_node("WeaponSprite2D/Marker2D") as Marker2D

@onready var cayote_timer: Timer = $CayoteTimer
@onready var jumpbuffer_timer: Timer = $JumpBufferTimer
@onready var JumpHang_Timer: Timer = $JumpHangTimer
@onready var NoDamage_Timer: Timer = $NoDamageTimer

@onready var current_health: int = max_health

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float
var jump_active: bool = false
var was_on_floor: bool = true

const JUMP_VELOCITY: float = -975.0
const TOP_SPEED: float = 600.0
const ACCELERATION: float = 3000.0
const DECELERATION: float = 3000.0

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position
	add_to_group("player")

func _physics_process(delta: float) -> void:
	previous_position = global_position
	var mouse_pos: Vector2 = get_global_mouse_position()

	if not is_on_floor():
		if velocity.y < 0.0:
			velocity.y += gravity * (rising_gravity_multiplier if not JumpHang_Timer.is_stopped() else 1.0) * delta
		else:
			velocity.y += gravity * falling_gravity_multiplier * delta
	else:
		if not JumpHang_Timer.is_stopped():
			JumpHang_Timer.stop()

	if jump_active and velocity.y >= 0.0:
		jump_active = false

	if is_on_floor():
		was_on_floor = true
		if not cayote_timer.is_stopped():
			cayote_timer.stop()
	else:
		if was_on_floor:
			cayote_timer.start()
			was_on_floor = false

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

	var direction: float = Input.get_axis("left", "right")
	velocity.x = move_toward(velocity.x, direction * TOP_SPEED, (ACCELERATION if direction != 0.0 else DECELERATION) * delta)

	main.play("run" if direction != 0.0 else "iddle")
	visuals.scale.x = -1.0 if mouse_pos.x < global_position.x else 1.0
	var local_mouse: Vector2 = visuals.to_local(mouse_pos)
	wep.rotation = clamp(local_mouse.angle(), deg_to_rad(-50.0), deg_to_rad(50.0))

	if Input.is_action_pressed("Shoot"):
		Projectile.shoot(proj_marker.global_position, mouse_pos, projectile_scene, self)

	move_and_slide()


func take_damage(amount: int) -> void:
	if NoDamage_Timer.is_stopped():
		current_health = max(current_health - amount, 0)
		update_health_bar()
		NoDamage_Timer.start()
		if current_health <= 0:
			die()

func die() -> void:
	queue_free()

func update_health_bar() -> void:
	var hp_bar_node: Node = get_tree().get_first_node_in_group("playerHP")
	if hp_bar_node:
		var hp_bar: ProgressBar = hp_bar_node.get_node("ProgressBar_health") as ProgressBar
		var timer: Timer = hp_bar_node.get_node("Timer") as Timer
		hp_bar.value = float(current_health) / float(max_health) * 100.0
		timer.start()
