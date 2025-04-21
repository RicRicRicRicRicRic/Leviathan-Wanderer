# player.gd
extends "res://scripts/Optimization/Interpolate.gd"

@export var max_health: int = 1000
@export var rising_gravity_multiplier: float = 2.2
@export var falling_gravity_multiplier: float = 2.2
@export var knockback_power:  float = 1200.0
@export var onair_knockback_power: float = 750.0
@export var projectile_scene: PackedScene = preload("res://scene/projectile.tscn")

@onready var visuals: Node2D = $Node2D
@onready var main: AnimatedSprite2D = visuals.get_node("CharacterSprite2D")
@onready var wep: Node2D = visuals.get_node("WeaponSprite2D")
@onready var proj_marker: Marker2D = visuals.get_node("WeaponSprite2D/Marker2D")
@onready var cayote_timer: Timer = $CayoteTimer
@onready var jumpbuffer_timer: Timer = $JumpBufferTimer
@onready var JumpHang_Timer: Timer  = $JumpHangTimer
@onready var NoDamage_Timer: Timer = $NoDamageTimer
@onready var time_to_apex: float = -JUMP_VELOCITY / (gravity * rising_gravity_multiplier)
@onready var base_time_to_apex: float = -JUMP_VELOCITY / gravity
@onready var jump_hang_duration: float = base_time_to_apex - time_to_apex
@onready var _jump_height: float = (JUMP_VELOCITY * JUMP_VELOCITY) / (2.0 * gravity * rising_gravity_multiplier)
@onready var time_to_fall: float = sqrt(2.0 * _jump_height / (gravity * falling_gravity_multiplier))

const JUMP_VELOCITY: float = -700.0
const TOP_SPEED: float = 600.0
const ACCELERATION: float = 3000.0
const DECELERATION: float = 3000.0

var speed_multiplier:        float          = 1.0
var jump_active:             bool           = false
var was_on_floor:            bool           = true
var current_health:          int            = max_health
var gravity:                 float          = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position
	add_to_group("player")
	JumpHang_Timer.wait_time = jump_hang_duration

func _physics_process(delta: float) -> void:
	previous_position = global_position
	var mouse_pos: Vector2 = get_global_mouse_position()

	_handle_vertical_movement(delta)
	_handle_jumping()
	_handle_horizontal_movement(delta)
	_play_animations()
	_handle_visuals(mouse_pos)

	move_and_slide()

func _handle_vertical_movement(delta: float) -> void:
	if not is_on_floor():
		if velocity.y < 0.0:
			var rise_mul: float = rising_gravity_multiplier
			if not JumpHang_Timer.is_stopped():
				rise_mul = 1.0
			velocity.y += gravity * rise_mul * delta
		else:
			velocity.y += gravity * falling_gravity_multiplier * delta
	else:
		if not JumpHang_Timer.is_stopped():
			JumpHang_Timer.stop()

	if jump_active and velocity.y >= 0.0:
		jump_active = false

	_handle_coyote_time()

func _handle_coyote_time() -> void:
	if is_on_floor():
		was_on_floor = true
		if not cayote_timer.is_stopped():
			cayote_timer.stop()
	else:
		if was_on_floor:
			cayote_timer.start()
			was_on_floor = false

func _handle_jumping() -> void:
	if Input.is_action_just_pressed("jump"):
		if (is_on_floor() or not cayote_timer.is_stopped()) and not jump_active:
			_perform_jump()
		elif jumpbuffer_timer.is_stopped():
			jumpbuffer_timer.start()

	if is_on_floor() and not jumpbuffer_timer.is_stopped() and not jump_active:
		_perform_jump()

func _perform_jump() -> void:
	velocity.y = JUMP_VELOCITY
	JumpHang_Timer.start()
	cayote_timer.stop()
	jumpbuffer_timer.stop()
	jump_active = true

func _handle_horizontal_movement(delta: float) -> void:
	var direction: float = Input.get_axis("left", "right")
	var accel: float = DECELERATION
	if direction != 0.0:
		accel = ACCELERATION
	velocity.x = move_toward(velocity.x, direction * TOP_SPEED * speed_multiplier, accel * delta)

func _play_animations() -> void:
	if not is_on_floor():
		if not JumpHang_Timer.is_stopped():
			main.play("jump_acce")
			_adjust_animation_speed("jump_acce", jump_hang_duration)
		elif velocity.y < 0.0:
			main.play("jump_hang")
			_adjust_animation_speed("jump_hang", time_to_apex)
		else:
			main.play("jump_decce")
			_adjust_animation_speed("jump_decce", time_to_fall)
	else:
		if Input.get_axis("left", "right") != 0.0:
			main.play("run")
		else:
			main.play("iddle")
		main.speed_scale = 1.0

func _adjust_animation_speed(anim_name: String, duration: float) -> void:
	var frames: int = main.sprite_frames.get_frame_count(anim_name)
	var fps: float   = main.sprite_frames.get_animation_speed(anim_name)
	var anim_duration: float = frames / fps

	if anim_duration > 0.0 and duration > 0.0:
		main.speed_scale = anim_duration / duration
	else:
		main.speed_scale = 1.0

func _handle_visuals(mouse_pos: Vector2) -> void:
	if mouse_pos.x < global_position.x:
		visuals.scale.x = -1.0
	else:
		visuals.scale.x = 1.0

	var local_mouse: Vector2 = visuals.to_local(mouse_pos)
	wep.rotation = clamp(local_mouse.angle(), deg_to_rad(-50.0), deg_to_rad(50.0))

	if Input.is_action_pressed("Shoot"):
		Projectile.shoot(proj_marker.global_position, mouse_pos, projectile_scene, self)

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
		var hp_bar: ProgressBar = hp_bar_node.get_node("ProgressBar_health")
		var timer: Timer       = hp_bar_node.get_node("Timer")
		hp_bar.value = float(current_health) / float(max_health) * 100.0
		timer.start()

func knockback(enemy_Velocity: Vector2) -> void:
	var current_knockback: float = onair_knockback_power
	if is_on_floor():
		current_knockback = knockback_power

	var knock_dir: Vector2 = (enemy_Velocity - velocity).normalized() * current_knockback
	velocity = knock_dir
	move_and_slide()

func apply_slow(multiplier: float) -> void:
	speed_multiplier = multiplier

func reset_speed() -> void:
	speed_multiplier = 1.0
