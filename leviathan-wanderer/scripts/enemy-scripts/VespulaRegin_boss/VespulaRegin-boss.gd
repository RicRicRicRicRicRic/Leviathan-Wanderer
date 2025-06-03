# VespulaRegin-boss.gd
extends CharacterBody2D

@export var stinger_scene: PackedScene = preload("res://scene/enemyscene/VespulaRegin-boss/vespula_stinger.tscn")
@export var larvae_egg: PackedScene = preload("res://scene/enemyscene/VespulaRegin-boss/larvae_egg.tscn")
@export var shield: PackedScene = preload("res://scene/enemyscene/VespulaRegin-boss/shield.tscn")

@onready var visuals: Node2D = $Node2D_visuals
@onready var timer: Timer = $Timer
@onready var projectile_origin: Marker2D = $Node2D_visuals/Marker2D

@export var carcass: PackedScene = preload("res://scene/enemyscene/VespulaRegin-boss/vespula_regin_carcass.tscn")

@export var triple_shot_fire_rate: float = 0.85
@export var triple_shot_duration: float = 7.75
@export var triple_shot_offset_degrees: float = 15.0

@export var single_shot_barrage_fire_rate: float = 0.35
@export var single_shot_barrage_duration: float = 5.0

@export var larvae_egg_fire_rate: float = 2.0
@export var larvae_egg_duration: float = 7.0
@export var larvae_egg_speed: float = 200.0

@export var horizontal_follow_speed: float = 80.0
@export var horizontal_follow_lerp_speed: float = 1.5

@export var alternating_shot_fire_rate: float = 0.95
@export var double_shot_offset_degrees_shield: float = 15.0
@export var shield_cooldown_duration: float
@export var shield_spawn_offset_y: float = 50.0

var max_health: float = 30000.0
var current_health: float = max_health
var is_enraged: bool = false

signal health_changed(new_health_percent: float)
signal boss_defeated

enum AttackState {
	STATE_IDLE,
	STATE_TRIPLE_SHOT,
	STATE_COOLDOWN_AFTER_TRIPLE_SHOT,
	STATE_SINGLE_SHOT_BARRAGE,
	STATE_COOLDOWN_AFTER_SINGLE_SHOT_BARRAGE,
	STATE_LARVAE_EGG_SHOT,
	STATE_COOLDOWN_AFTER_LARVAE_EGG_SHOT,
	STATE_SHIELDED_ATTACK,
	STATE_COOLDOWN_AFTER_SHIELD,
}

var _current_attack_state: AttackState = AttackState.STATE_IDLE
var _current_fire_timer: float = 0.0
var _time_in_current_phase: float = 0.0
var _can_follow_player: bool = false
var _active_shield_instance: Node = null
var _is_next_shot_single: bool = true

func _ready() -> void:
	add_to_group("boss")
	add_to_group("enemy")
	shield_cooldown_duration = timer.wait_time

	randomize()

	health_changed.emit(current_health / max_health * 100.0)

	timer.timeout.connect(_on_attack_phase_transition)

	var room_node = get_parent()
	if room_node and room_node.has_signal("boss_ready_for_attack"):
		room_node.boss_ready_for_attack.connect(_on_room_boss_ready_for_attack)

func _physics_process(delta: float) -> void:
	if _can_follow_player:
		var player_position = get_player_position()
		var target_x = player_position.x
		
		global_position.x = lerp(global_position.x, target_x, horizontal_follow_lerp_speed * delta)
		
	if _current_attack_state == AttackState.STATE_SHIELDED_ATTACK and _active_shield_instance and is_instance_valid(_active_shield_instance):
		_active_shield_instance.global_position = global_position + Vector2(0, shield_spawn_offset_y)

	match _current_attack_state:
		AttackState.STATE_TRIPLE_SHOT:
			_time_in_current_phase += delta
			_current_fire_timer += delta

			if _current_fire_timer >= triple_shot_fire_rate:
				_current_fire_timer = 0.0
				_fire_triple_stinger_at_player()

			if _time_in_current_phase >= triple_shot_duration:
				_set_state(AttackState.STATE_COOLDOWN_AFTER_TRIPLE_SHOT)
		AttackState.STATE_COOLDOWN_AFTER_TRIPLE_SHOT:
			pass
		AttackState.STATE_SINGLE_SHOT_BARRAGE:
			_time_in_current_phase += delta
			_current_fire_timer += delta

			if _current_fire_timer >= single_shot_barrage_fire_rate:
				_current_fire_timer = 0.0
				_fire_stinger_towards_target((get_player_position() - projectile_origin.global_position).normalized())

			if _time_in_current_phase >= single_shot_barrage_duration:
				_set_state(AttackState.STATE_COOLDOWN_AFTER_SINGLE_SHOT_BARRAGE)
		AttackState.STATE_COOLDOWN_AFTER_SINGLE_SHOT_BARRAGE:
			pass
		AttackState.STATE_LARVAE_EGG_SHOT:
			_time_in_current_phase += delta
			_current_fire_timer += delta

			if _current_fire_timer >= larvae_egg_fire_rate:
				_current_fire_timer = 0.0
				_fire_single_larvae_egg()
			
			if _time_in_current_phase >= larvae_egg_duration:
				_set_state(AttackState.STATE_COOLDOWN_AFTER_LARVAE_EGG_SHOT)
		AttackState.STATE_COOLDOWN_AFTER_LARVAE_EGG_SHOT:
			pass
		AttackState.STATE_SHIELDED_ATTACK:
			_current_fire_timer += delta

			if _current_fire_timer >= alternating_shot_fire_rate:
				_current_fire_timer = 0.0
				if _is_next_shot_single:
					_fire_stinger_towards_target((get_player_position() - projectile_origin.global_position).normalized())
				else:
					_fire_double_stinger_at_player()
				_is_next_shot_single = not _is_next_shot_single
		AttackState.STATE_COOLDOWN_AFTER_SHIELD:
			pass
		AttackState.STATE_IDLE:
			pass

func take_damage(amount: float) -> void:
	if _current_attack_state == AttackState.STATE_SHIELDED_ATTACK and _active_shield_instance and is_instance_valid(_active_shield_instance):
		if _active_shield_instance.has_method("take_damage"):
			_active_shield_instance.take_damage(amount)
		return

	current_health -= amount
	current_health = max(0, current_health)

	health_changed.emit(current_health / max_health * 100.0)

	if current_health <= 0:
		call_deferred("_deferred_death")
	elif current_health <= max_health * 0.25 and not is_enraged:
		is_enraged = true
		print("Vespula Regina is enraged!")

func _deferred_death() -> void:
	print("Vespula Regina defeated!")
	boss_defeated.emit() 

	if carcass:
		var carcass_instance = carcass.instantiate()
		get_parent().add_child(carcass_instance)
		carcass_instance.global_position = global_position
	
	if _active_shield_instance and is_instance_valid(_active_shield_instance):
		_active_shield_instance.queue_free()

	queue_free()

func _on_room_boss_ready_for_attack() -> void:
	_set_state(AttackState.STATE_TRIPLE_SHOT)
	_can_follow_player = true

func _set_state(new_state: AttackState) -> void:
	_current_attack_state = new_state
	_current_fire_timer = 0.0
	_time_in_current_phase = 0.0
	timer.stop()

	match _current_attack_state:
		AttackState.STATE_IDLE:
			pass
		AttackState.STATE_TRIPLE_SHOT:
			pass
		AttackState.STATE_COOLDOWN_AFTER_TRIPLE_SHOT:
			timer.wait_time = 2.0
			timer.start()
		AttackState.STATE_SINGLE_SHOT_BARRAGE:
			pass
		AttackState.STATE_COOLDOWN_AFTER_SINGLE_SHOT_BARRAGE:
			timer.wait_time = 2.0
			timer.start()
		AttackState.STATE_LARVAE_EGG_SHOT:
			_current_fire_timer = 0.0
		AttackState.STATE_COOLDOWN_AFTER_LARVAE_EGG_SHOT:
			timer.wait_time = 2.0
			timer.start()
		AttackState.STATE_SHIELDED_ATTACK:
			_is_next_shot_single = true
			_current_fire_timer = 0.0
			if shield:
				_active_shield_instance = shield.instantiate()
				get_parent().add_child(_active_shield_instance)
				_active_shield_instance.global_position = global_position + Vector2(0, shield_spawn_offset_y)
				if _active_shield_instance.has_signal("shield_broken"):
					_active_shield_instance.shield_broken.connect(_on_shield_broken)
				else:
					print("Warning: Shield scene does not emit 'shield_broken' signal.")
			else:
				print("Error: Shield PackedScene is not assigned.")
				_set_state(AttackState.STATE_COOLDOWN_AFTER_SHIELD)
		AttackState.STATE_COOLDOWN_AFTER_SHIELD:
			timer.wait_time = shield_cooldown_duration
			timer.start()

func _on_attack_phase_transition() -> void:
	match _current_attack_state:
		AttackState.STATE_COOLDOWN_AFTER_TRIPLE_SHOT:
			_set_state(AttackState.STATE_SINGLE_SHOT_BARRAGE)
		AttackState.STATE_COOLDOWN_AFTER_SINGLE_SHOT_BARRAGE:
			_set_state(AttackState.STATE_LARVAE_EGG_SHOT)
		AttackState.STATE_COOLDOWN_AFTER_LARVAE_EGG_SHOT:
			_set_state(AttackState.STATE_SHIELDED_ATTACK)
		AttackState.STATE_COOLDOWN_AFTER_SHIELD:
			_set_state(AttackState.STATE_TRIPLE_SHOT)

func get_player_position() -> Vector2:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0].global_position
	return Vector2(0, 0)

func _fire_stinger_towards_target(target_direction_vector: Vector2) -> void:
	if not stinger_scene:
		return

	var stinger_instance = stinger_scene.instantiate()
	get_parent().add_child(stinger_instance)

	stinger_instance.global_position = projectile_origin.global_position
	stinger_instance.rotation = target_direction_vector.angle()

	if stinger_instance.has_method("set_direction"):
		stinger_instance.set_direction(target_direction_vector.normalized())
	else:
		stinger_instance.linear_velocity = target_direction_vector.normalized() * stinger_instance.current_speed

func _fire_triple_stinger_at_player() -> void:
	var player_position = get_player_position()
	var base_direction = (player_position - projectile_origin.global_position).normalized()

	_fire_stinger_towards_target(base_direction)

	var right_offset_direction = base_direction.rotated(deg_to_rad(-triple_shot_offset_degrees))
	_fire_stinger_towards_target(right_offset_direction)

	var left_offset_direction = base_direction.rotated(deg_to_rad(triple_shot_offset_degrees))
	_fire_stinger_towards_target(left_offset_direction)

func _fire_double_stinger_at_player() -> void:
	var player_position = get_player_position()
	var base_direction = (player_position - projectile_origin.global_position).normalized()

	var right_offset_direction = base_direction.rotated(deg_to_rad(-double_shot_offset_degrees_shield))
	_fire_stinger_towards_target(right_offset_direction)

	var left_offset_direction = base_direction.rotated(deg_to_rad(double_shot_offset_degrees_shield))
	_fire_stinger_towards_target(left_offset_direction)

func _fire_single_larvae_egg() -> void:
	if not larvae_egg:
		return

	var player_position = get_player_position()
	var direction_to_player = (player_position - projectile_origin.global_position).normalized()

	var egg_instance = larvae_egg.instantiate()
	get_parent().add_child(egg_instance)
	egg_instance.global_position = projectile_origin.global_position
	egg_instance.rotation = direction_to_player.angle()
	
	if egg_instance.has_method("set_direction"):
		egg_instance.set_direction(direction_to_player)
	else:
		egg_instance.linear_velocity = direction_to_player * larvae_egg_speed

func _on_shield_broken() -> void:
	print("Boss shield broken!")
	_active_shield_instance = null
	_set_state(AttackState.STATE_COOLDOWN_AFTER_SHIELD)
