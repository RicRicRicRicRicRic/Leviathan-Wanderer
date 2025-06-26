# player.gd
extends "res://scripts/Utility/Interpolate.gd"

@export var default_max_health: int = 1000
@export var default_top_speed: float = 600.0
@export var default_jump_velocity: float = -700.0

@export var default_max_mana: int = 1000 
@export var default_mana_regen_value: int = 3 
@export var default_mana_regen_speed: float = 0.01 

@export var rising_gravity_multiplier: float = 2.2
@export var falling_gravity_multiplier: float = 2.2
@export var projectile_scene: PackedScene = preload("res://scene/Player_scene/projectile.tscn")
@export var teleport_indicator_scene: PackedScene = preload("res://scene/Player_scene/teleprot.tscn")
@export var laser_scene: PackedScene = preload("res://scene/Player_scene/laser.tscn")
@export var limitless_technique_scene: PackedScene = preload("res://scene/Player_scene/limitless.tscn") 


@onready var visuals: Node2D = $Node2D
@onready var main: AnimatedSprite2D = visuals.get_node("CharacterSprite2D")
@onready var wep: Node2D = visuals.get_node("WeaponSprite2D")
@onready var proj_marker: Marker2D = wep.get_node("Marker2D")
@onready var laser_marker: Marker2D = wep.get_node("Marker2D_laser")
@onready var cayote_timer: Timer = $CayoteTimer
@onready var jumpbuffer_timer: Timer = $JumpBufferTimer
@onready var JumpHang_Timer: Timer = $JumpHangTimer
@onready var NoDamage_Timer: Timer = $NoDamageTimer
@onready var start_mana_regen: Timer = $Timer_mana_regen

const ACCELERATION: float = 3000.0
const DECELERATION: float = 3000.0
const LIMITLESS_TECHNIQUE_RADIUS: float = 500.0 

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
var current_health: int
var current_mana: int
var combo_meter: int = 0
@export var max_combo_meter: int = 1000 
var teleport_cancelled: bool = false
var teleport_indicator_instance: Node2D = null 
var is_laser_active: bool = false

var is_mana_regen_active: bool = false
var time_since_last_mana_regen_tick: float = 0.0

var effective_top_speed: float
var effective_max_health: int
var effective_jump_velocity: float
var effective_max_mana: int 
var effective_mana_regen_value: int 
var effective_mana_regen_speed: float 

var has_double_jumped: bool = false
var is_limitless_technique_active: bool = false 
var limitless_technique_instance: Area2D = null 

func _ready() -> void:
	if GlobalGameState.base_player_max_health == 0:
		GlobalGameState.base_player_max_health = default_max_health
		GlobalGameState.base_player_top_speed = default_top_speed
		GlobalGameState.base_player_jump_velocity = default_jump_velocity
		GlobalGameState.base_player_max_mana = default_max_mana 

	update_effective_stats()

	current_health = effective_max_health 
	current_mana = effective_max_mana 

	time_to_apex = -effective_jump_velocity / (gravity * rising_gravity_multiplier)
	base_time_to_apex = -effective_jump_velocity / gravity 
	jump_hang_duration = base_time_to_apex - time_to_apex
	_jump_height = (effective_jump_velocity * effective_jump_velocity) / (2.0 * gravity * rising_gravity_multiplier)
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

	if limitless_technique_scene:
		limitless_technique_instance = limitless_technique_scene.instantiate()
		add_child(limitless_technique_instance)
		limitless_technique_instance.monitoring = false 
		limitless_technique_instance.monitorable = false 
		limitless_technique_instance.position = Vector2.ZERO
		
		if limitless_technique_instance.has_signal("technique_ended"):
			limitless_technique_instance.technique_ended.connect(_on_limitless_technique_ended)


func update_effective_stats() -> void:
	effective_max_health = int(GlobalGameState.base_player_max_health * GlobalGameState.player_max_health_multiplier)
	effective_top_speed = GlobalGameState.base_player_top_speed * GlobalGameState.player_top_speed_multiplier
	effective_jump_velocity = GlobalGameState.base_player_jump_velocity * GlobalGameState.player_jump_velocity_multiplier
	effective_max_mana = int(GlobalGameState.base_player_max_mana * GlobalGameState.player_max_mana_multiplier)
	effective_mana_regen_value = int(default_mana_regen_value * GlobalGameState.player_mana_regen_value_multiplier)
	effective_mana_regen_speed = default_mana_regen_speed / GlobalGameState.player_mana_regen_speed_multiplier

	time_to_apex = -effective_jump_velocity / (gravity * rising_gravity_multiplier)
	base_time_to_apex = -effective_jump_velocity / gravity
	jump_hang_duration = base_time_to_apex - time_to_apex
	_jump_height = (effective_jump_velocity * effective_jump_velocity) / (2.0 * gravity * rising_gravity_multiplier)
	time_to_fall = sqrt(2.0 * _jump_height / (gravity * falling_gravity_multiplier))
	
	main.time_to_apex = time_to_apex
	main.jump_hang_duration = JumpHang_Timer.wait_time
	main.time_to_fall = time_to_fall


func _physics_process(delta: float) -> void:
	previous_position = global_position

	if Input.is_action_pressed("Shoot"):
		if not start_mana_regen.is_stopped():
			start_mana_regen.stop()
		is_mana_regen_active = false
		time_since_last_mana_regen_tick = 0.0
	elif Input.is_action_just_released("Shoot"):
		start_mana_regen.start()

	if is_mana_regen_active and current_mana < effective_max_mana:
		time_since_last_mana_regen_tick += delta
		if time_since_last_mana_regen_tick >= effective_mana_regen_speed:
			current_mana = min(current_mana + effective_mana_regen_value, effective_max_mana)
			update_mana_bar()
			time_since_last_mana_regen_tick -= effective_mana_regen_speed
			if current_mana >= effective_max_mana:
				is_mana_regen_active = false
				time_since_last_mana_regen_tick = 0.0

	if Input.is_action_just_pressed("Teleport"):
		teleport_cancelled = false
		if teleport_indicator_instance == null:
			teleport_indicator_instance = teleport_indicator_scene.instantiate()
			get_parent().add_child(teleport_indicator_instance)
			if teleport_indicator_instance.has_method("set_teleport_data"):
				teleport_indicator_instance.set_teleport_data(self)
		else:
			if teleport_indicator_instance.has_method("reset_indicator"):
				teleport_indicator_instance.reset_indicator()
			else:
				teleport_indicator_instance.visible = true
				teleport_indicator_instance.set_process(true)
				if teleport_indicator_instance.has_method("set_teleport_data"):
					teleport_indicator_instance.set_teleport_data(self)

	if Input.is_action_pressed("Teleport"):
		if teleport_indicator_instance and teleport_indicator_instance.visible:
			var mouse_position = get_global_mouse_position()
			teleport_indicator_instance.update_position(mouse_position)

	if Input.is_action_just_pressed("Cancel_input") and Input.is_action_pressed("Teleport"):
		teleport_cancelled = true
		if teleport_indicator_instance:
			if teleport_indicator_instance.has_method("cancel_teleport"):
				teleport_indicator_instance.cancel_teleport()

	if Input.is_action_just_released("Teleport"):
		if teleport_indicator_instance and teleport_indicator_instance.visible:
			var mouse_position = get_global_mouse_position()
			teleport_indicator_instance.update_position(mouse_position)
			if teleport_indicator_instance.has_method("perform_teleport"):
				teleport_indicator_instance.perform_teleport()
		elif teleport_indicator_instance and not teleport_indicator_instance.visible:
			if teleport_indicator_instance.has_method("cancel_teleport"):
				teleport_indicator_instance.cancel_teleport()

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
		has_double_jumped = false 

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
		elif GlobalGameState.can_double_jump and not has_double_jumped and current_mana >= GlobalGameState.double_jump_mana_cost:
			_perform_double_jump()
		elif jumpbuffer_timer.is_stopped():
			jumpbuffer_timer.start()
	if is_on_floor() and not jumpbuffer_timer.is_stopped() and not jump_active:
		_perform_jump()

func _perform_jump() -> void:
	velocity.y = effective_jump_velocity * jump_multiplier
	JumpHang_Timer.start()
	cayote_timer.stop()
	jumpbuffer_timer.stop()
	jump_active = true

func _perform_double_jump() -> void: 
	velocity.y = effective_jump_velocity * jump_multiplier 
	current_mana = max(0, current_mana - GlobalGameState.double_jump_mana_cost)
	update_mana_bar()
	has_double_jumped = true
	JumpHang_Timer.start() 
	jump_active = true
	if start_mana_regen and start_mana_regen.is_stopped():
		start_mana_regen.start()


func _handle_horizontal_movement(delta: float) -> void:
	var direction: float = Input.get_axis("left", "right")
	var accel: float = DECELERATION
	if direction != 0.0:
		accel = ACCELERATION
	velocity.x = move_toward(velocity.x, direction * effective_top_speed * speed_multiplier, accel * delta)

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
		
		if GlobalGameState.limitless_technique_enabled and limitless_technique_instance and \
		   limitless_technique_instance.call("can_activate"): 
			_activate_limitless_technique()

func _activate_limitless_technique() -> void: 
	is_limitless_technique_active = true

	if limitless_technique_instance:
		limitless_technique_instance.activate_technique() 

func _on_limitless_technique_ended() -> void: 
	is_limitless_technique_active = false

func die() -> void:
	current_health = effective_max_health
	update_health_bar()

func update_health_bar() -> void:
	var hp_bar_node: Node = get_tree().get_first_node_in_group("player_conditions")
	if hp_bar_node:
		var hp_bar: ProgressBar = hp_bar_node.get_node("ProgressBar_health")
		var timer: Timer = hp_bar_node.get_node("Timer")
		hp_bar.value = float(current_health) / float(effective_max_health) * 100.0
		timer.start()

func update_mana_bar() -> void:
	var mana_bar_node: Node = get_tree().get_first_node_in_group("player_conditions")
	if mana_bar_node:
		var mana_bar_main: ProgressBar = mana_bar_node.get_node("ProgressBar_mana")
		if mana_bar_main:
			mana_bar_main.value = float(current_mana) / float(effective_max_mana) * 100.0 

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
