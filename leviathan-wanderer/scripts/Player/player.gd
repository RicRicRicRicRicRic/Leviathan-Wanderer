# player.gd
extends "res://scripts/Utility/Interpolate.gd"

@export var max_health: int = 1000
@export var max_mana: int = 1000
@export var rising_gravity_multiplier: float = 2.2
@export var falling_gravity_multiplier: float = 2.2
@export var projectile_scene: PackedScene = preload("res://scene/Player_scene/projectile.tscn")
@export var teleport_indicator_scene: PackedScene = preload("res://scene/Player_scene/teleprot.tscn")
@export var laser_scene: PackedScene = preload("res://scene/Player_scene/laser.tscn")

@export var mana_regen_value: int = 3
@export var mana_regen_speed: float = 0.01

@onready var visuals: Node2D = $Node2D
@onready var main: AnimatedSprite2D = visuals.get_node("CharacterSprite2D")
@onready var wep: Node2D = visuals.get_node("WeaponSprite2D")
@onready var proj_marker: Marker2D = wep.get_node("Marker2D")
@onready var laser_marker: Marker2D = wep.get_node("Marker2D_laser")
@onready var cayote_timer: Timer = $CayoteTimer
@onready var jumpbuffer_timer: Timer = $JumpBufferTimer
@onready var teleport_cooldown: Timer = $TeleportCDTimer
@onready var JumpHang_Timer: Timer = $JumpHangTimer
@onready var NoDamage_Timer: Timer = $NoDamageTimer
@onready var start_mana_regen: Timer = $Timer_mana_regen

const JUMP_VELOCITY: float = -700.0
const TOP_SPEED: float = 600.0
const ACCELERATION: float = 3000.0
const DECELERATION: float = 3000.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var time_to_apex: float
var base_time_to_apex: float
var jump_hang_duration: float
var _jump_height: float
var time_to_fall: float

var jump_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var jump_active: bool = false
var was_on_floor: bool = true
var current_health: int = max_health
var current_mana: int = max_mana
var combo_meter: int = 0
@export var max_combo_meter: int = 1000 
var teleport_cancelled: bool = false
var teleport_indicator_instance: Node2D = null
var is_laser_active: bool = false

var is_mana_regen_active: bool = false
var time_since_last_mana_regen_tick: float = 0.0

func _ready() -> void:
	time_to_apex = -JUMP_VELOCITY / (gravity * rising_gravity_multiplier)
	base_time_to_apex = -JUMP_VELOCITY / gravity
	jump_hang_duration = base_time_to_apex - time_to_apex
	_jump_height = (JUMP_VELOCITY * JUMP_VELOCITY) / (2.0 * gravity * rising_gravity_multiplier)
	time_to_fall = sqrt(2.0 * _jump_height / (gravity * falling_gravity_multiplier))

	main.time_to_apex = time_to_apex
	main.jump_hang_duration = JumpHang_Timer.wait_time
	main.time_to_fall = time_to_fall

	interp_visuals = visuals
	previous_position = global_position

	add_to_group("player")

	update_health_bar()
	update_mana_bar()

	start_mana_regen.connect("timeout", Callable(self, "_on_mana_regen_delay_timeout"))

func _physics_process(delta: float) -> void:
	previous_position = global_position

	if Input.is_action_pressed("Shoot"):
		if not start_mana_regen.is_stopped():
			start_mana_regen.stop()
		is_mana_regen_active = false
		time_since_last_mana_regen_tick = 0.0
	elif Input.is_action_just_released("Shoot"):
		start_mana_regen.start()

	if is_mana_regen_active and current_mana < max_mana:
		time_since_last_mana_regen_tick += delta
		if time_since_last_mana_regen_tick >= mana_regen_speed:
			current_mana = min(current_mana + mana_regen_value, max_mana)
			update_mana_bar()
			time_since_last_mana_regen_tick -= mana_regen_speed
			if current_mana >= max_mana:
				is_mana_regen_active = false
				time_since_last_mana_regen_tick = 0.0

	if Input.is_action_just_pressed("Teleport"):
		teleport_cancelled = false
		if teleport_indicator_scene and teleport_indicator_instance == null:
			teleport_indicator_instance = teleport_indicator_scene.instantiate()
			get_parent().add_child(teleport_indicator_instance)
			if teleport_indicator_instance.has_method("set_teleport_data"):
				teleport_indicator_instance.set_teleport_data(self, teleport_cooldown)
	if Input.is_action_pressed("Teleport"):
		if teleport_indicator_instance:
			var mouse_position = get_global_mouse_position()
			teleport_indicator_instance.update_position(mouse_position)
	if Input.is_action_just_pressed("Cancel_input") and Input.is_action_pressed("Teleport"):
		teleport_cancelled = true
		if teleport_indicator_instance:
			teleport_indicator_instance.queue_free()
			teleport_indicator_instance = null
	if Input.is_action_just_released("Teleport"):
		if teleport_indicator_instance:
			var mouse_position = get_global_mouse_position()
			teleport_indicator_instance.update_position(mouse_position)
			teleport_indicator_instance.perform_teleport()
			teleport_indicator_instance = null

	if Input.is_action_just_pressed("Ultimate"):
		if combo_meter == max_combo_meter and not is_laser_active:
			if laser_scene:
				var laser_instance = laser_scene.instantiate()
				laser_instance.global_position = laser_marker.global_position
				get_parent().add_child(laser_instance)
				is_laser_active = true
				if laser_instance.has_signal("laser_finished_firing"):
					laser_instance.connect("laser_finished_firing", Callable(self, "_on_laser_finished_firing"))
				combo_meter = 0
		else:
			pass 

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
	velocity.y = JUMP_VELOCITY * jump_multiplier
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
		main.play_animation_in_air(not JumpHang_Timer.is_stopped(), velocity.y)
	else:
		main.play_animation_on_floor(Input.get_axis("left", "right"))

func _handle_visuals(mouse_pos: Vector2) -> void:
	if mouse_pos.x < global_position.x:
		visuals.scale.x = -1.0
	else:
		visuals.scale.x = 1.0

	var local_mouse: Vector2 = visuals.to_local(mouse_pos)
	wep.rotation = clamp(local_mouse.angle(), deg_to_rad(-50.0), deg_to_rad(50.0))

	if Input.is_action_pressed("Shoot") and not is_laser_active:
		Projectile.shoot(proj_marker.global_position, mouse_pos, projectile_scene, self)

func take_damage(amount: int, knockback_force: Vector2 = Vector2.ZERO) -> void:
	if NoDamage_Timer.is_stopped():
		current_health = max(current_health - amount, 0)
		update_health_bar()
		NoDamage_Timer.start()
		if knockback_force != Vector2.ZERO:
			knockback(knockback_force)
		if current_health <= 0:
			die()

func die() -> void:
	current_health = max_health
	update_health_bar()

func update_health_bar() -> void:
	var hp_bar_node: Node = get_tree().get_first_node_in_group("player_conditions")
	if hp_bar_node:
		var hp_bar: ProgressBar = hp_bar_node.get_node("ProgressBar_health")
		var timer: Timer = hp_bar_node.get_node("Timer")
		hp_bar.value = float(current_health) / float(max_health) * 100.0
		timer.start()

func update_mana_bar() -> void:
	var mana_bar_node: Node = get_tree().get_first_node_in_group("player_conditions")
	if mana_bar_node:
		var mana_bar_main: ProgressBar = mana_bar_node.get_node("ProgressBar_mana")

		if mana_bar_main:
			pass

func add_combo(amount: int) -> void:
	combo_meter = min(combo_meter + amount, max_combo_meter)

func knockback(force: Vector2) -> void:
	velocity = force

func apply_slow(multiplier: float) -> void:
	speed_multiplier = multiplier

func reset_speed() -> void:
	speed_multiplier = 1.0

func apply_weakend_jump(multiplier: float) -> void:
	jump_multiplier = multiplier

func reset_jump() -> void:
	jump_multiplier = 1.0

func _on_laser_finished_firing() -> void:
	is_laser_active = false
	start_mana_regen.start()

func _on_mana_regen_delay_timeout() -> void:
	is_mana_regen_active = true
	time_since_last_mana_regen_tick = 0.0
