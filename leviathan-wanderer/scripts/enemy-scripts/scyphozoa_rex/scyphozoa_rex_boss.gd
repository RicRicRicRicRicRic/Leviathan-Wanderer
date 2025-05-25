# scyphozoa_rex_boss.gd
extends "res://scripts/Utility/Interpolate.gd"

@onready var visuals: Node2D = $Node2D_visuals
@onready var timer: Timer = $Timer
@onready var projectile_origin: Marker2D = $Node2D_visuals/Sprite2D_pupil/Marker2D_projectile
@onready var node2d_pattern1: Node2D = $Node2D_visuals/Sprite2D_pupil/Node2D_attack/Node2D_pattern1
@onready var node2d_pattern2: Node2D = $Node2D_visuals/Sprite2D_pupil/Node2D_attack/Node2D_pattern2
@onready var marker2d_7: Marker2D = $Node2D_visuals/Sprite2D_pupil/Node2D_attack/Node2D_pattern1/Marker2D7
@onready var marker2d_5: Marker2D = $Node2D_visuals/Sprite2D_pupil/Node2D_attack/Node2D_pattern1/Marker2D5
@export var projectile_scene: PackedScene = preload("res://scene/enemyscene/ScyphozoaRex-boss/scyphozoa_rex_projectile.tscn")
@export var carcass: PackedScene = preload("res://scene/enemyscene/ScyphozoaRex-boss/ScyphozoaRex_carcass.tscn")

var hover_amplitude: float = -0.5
var hover_speed: float = 0.75

@export var barrage_active_duration: float = 10.0
@export var cooldown_duration_between_phases: float = 3.0
@export var fire_rate_interval: float = 0.1
@export var pattern_shot_delay: float = 1
@export var pattern_sequence_repeats: int = 6

@export var burst_total_sequences: int = 6
@export var burst_bullets_per_sequence: int = 3
@export var burst_bullet_delay: float = 0.1
@export var burst_sequence_delay: float = 1.0

@export var barrage_burst_total_sequences: int = 6
@export var barrage_burst_bullets_per_burst: int = 5
@export var barrage_burst_bullet_delay: float = 0.1
@export var barrage_burst_sequence_delay: float = 1.0

@export var enraged_barrage_active_duration: float = 10.0
@export var enraged_cooldown_duration: float = 0.1
@export var enraged_fire_rate_interval: float = 0.05

var max_health: float = 50000.0
var current_health: float = max_health
var is_enraged: bool = false

signal health_changed(new_health_percent: float)

enum AttackState {
	STATE_IDLE,
	STATE_BARRAGE_ACTIVE,
	STATE_COOLDOWN_AFTER_BARRAGE,
	STATE_PATTERN1_ACTIVE,
	STATE_PATTERN2_ACTIVE,
	STATE_COOLDOWN_AFTER_PATTERN_PHASE,
	STATE_BURST_ATTACK,
	STATE_COOLDOWN_AFTER_BURST_ATTACK,
	STATE_BARRAGE_BURST,
	STATE_COOLDOWN_AFTER_BARRAGE_BURST,
	STATE_ENRAGED_BARRAGE_ACTIVE,
	STATE_COOLDOWN_ENRAGED_BARRAGE
}

var _time_elapsed: float = 0.0
var _current_attack_state: AttackState = AttackState.STATE_IDLE
var _current_fire_timer: float = 0.0
var _time_in_current_phase: float = 0.0

var _pattern_sequence_count: int = 0
var _burst_current_bullet_count: int = 0
var _burst_current_sequence_count: int = 0
var _burst_wait_for_sequence_start: bool = false

var _barrage_burst_current_sequence_repeat: int = 0
var _barrage_burst_current_bullet_in_burst: int = 0
var _barrage_burst_is_player_burst: bool = true
var _barrage_burst_waiting_for_delay: bool = false

var _enraged_target_index: int = 0

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position
	add_to_group("boss")
	add_to_group("enemy")

	randomize()

	timer.timeout.connect(_on_attack_phase_transition)
	
	var room_node = get_parent()
	if room_node and room_node.has_signal("boss_ready_for_attack"):
		room_node.boss_ready_for_attack.connect(_on_room_boss_ready_for_attack)

func take_damage(amount: float) -> void:
	current_health -= amount
	health_changed.emit(current_health / max_health * 100.0)
	if current_health <= 0:
		call_deferred("_deferred_death")
	elif current_health <= 10000.0 and not is_enraged:
		is_enraged = true
		_set_state(AttackState.STATE_ENRAGED_BARRAGE_ACTIVE)

func _deferred_death() -> void:
	if carcass:
		var carcass_instance = carcass.instantiate()
		get_parent().add_child(carcass_instance)
		carcass_instance.global_position = global_position
	queue_free()

func _on_room_boss_ready_for_attack() -> void:
	_set_state(AttackState.STATE_BARRAGE_ACTIVE)

func _set_state(new_state: AttackState) -> void:
	_current_attack_state = new_state
	_current_fire_timer = 0.0
	_time_in_current_phase = 0.0

	timer.stop()

	match _current_attack_state:
		AttackState.STATE_IDLE:
			pass
		AttackState.STATE_BARRAGE_ACTIVE:
			_pattern_sequence_count = 0
			_burst_current_sequence_count = 0
			_barrage_burst_current_sequence_repeat = 0
		AttackState.STATE_COOLDOWN_AFTER_BARRAGE:
			timer.wait_time = cooldown_duration_between_phases
			timer.start()
		AttackState.STATE_PATTERN1_ACTIVE:
			_fire_projectiles_towards_pattern_markers(node2d_pattern1)
		AttackState.STATE_PATTERN2_ACTIVE:
			_fire_projectiles_towards_pattern_markers(node2d_pattern2)
			_pattern_sequence_count += 1

			if _pattern_sequence_count >= pattern_sequence_repeats:
				pass 
			else:
				pass 

		AttackState.STATE_COOLDOWN_AFTER_PATTERN_PHASE:
			timer.wait_time = cooldown_duration_between_phases
			timer.start()
		AttackState.STATE_BURST_ATTACK:
			_burst_current_bullet_count = 0
			_burst_wait_for_sequence_start = false
			_current_fire_timer = 0.0
		AttackState.STATE_COOLDOWN_AFTER_BURST_ATTACK:
			timer.wait_time = cooldown_duration_between_phases
			timer.start()
		AttackState.STATE_BARRAGE_BURST:
			_barrage_burst_current_bullet_in_burst = 0
			_barrage_burst_is_player_burst = true
			_barrage_burst_waiting_for_delay = false
			_current_fire_timer = 0.0
			_fire_projectile_towards_target(get_player_position())
			_barrage_burst_current_bullet_in_burst += 1
		AttackState.STATE_COOLDOWN_AFTER_BARRAGE_BURST:
			timer.wait_time = cooldown_duration_between_phases
			timer.start()
		AttackState.STATE_ENRAGED_BARRAGE_ACTIVE:
			_time_in_current_phase = 0.0
			_current_fire_timer = 0.0
			_enraged_target_index = 0
		AttackState.STATE_COOLDOWN_ENRAGED_BARRAGE:
			timer.wait_time = enraged_cooldown_duration
			timer.start()

func _physics_process(delta: float) -> void:
	previous_position = global_position

	_time_elapsed += delta
	var hover_offset_y: float = sin(_time_elapsed * hover_speed) * hover_amplitude
	global_position.y += hover_offset_y

	if is_enraged:
		match _current_attack_state:
			AttackState.STATE_ENRAGED_BARRAGE_ACTIVE:
				_time_in_current_phase += delta
				_current_fire_timer += delta

				if _current_fire_timer >= enraged_fire_rate_interval:
					_current_fire_timer = 0.0
					
					if _enraged_target_index == 0:
						_fire_projectile_towards_target(get_player_position())
					elif _enraged_target_index == 1:
						_fire_projectile_towards_target(marker2d_7.global_position)
					elif _enraged_target_index == 2:
						_fire_projectile_towards_target(marker2d_5.global_position)
					
					_enraged_target_index = (_enraged_target_index + 1) % 3

				if _time_in_current_phase >= enraged_barrage_active_duration:
					_set_state(AttackState.STATE_COOLDOWN_ENRAGED_BARRAGE)
			AttackState.STATE_COOLDOWN_ENRAGED_BARRAGE:
				pass
		return

	match _current_attack_state:
		AttackState.STATE_IDLE:
			pass
		AttackState.STATE_BARRAGE_ACTIVE:
			_time_in_current_phase += delta
			_current_fire_timer += delta

			if _current_fire_timer >= fire_rate_interval:
				_current_fire_timer = 0.0
				_fire_projectile_towards_target(get_player_position())

			if _time_in_current_phase >= barrage_active_duration:
				_set_state(AttackState.STATE_COOLDOWN_AFTER_BARRAGE)
		AttackState.STATE_PATTERN1_ACTIVE:
			_time_in_current_phase += delta
			if _time_in_current_phase >= pattern_shot_delay:
				_set_state(AttackState.STATE_PATTERN2_ACTIVE)
		AttackState.STATE_PATTERN2_ACTIVE:
			_time_in_current_phase += delta
			if _time_in_current_phase >= pattern_shot_delay:
				if _pattern_sequence_count >= pattern_sequence_repeats:
					_set_state(AttackState.STATE_COOLDOWN_AFTER_PATTERN_PHASE)
				else:
					_set_state(AttackState.STATE_PATTERN1_ACTIVE)
		AttackState.STATE_BURST_ATTACK:
			_current_fire_timer += delta

			if _burst_wait_for_sequence_start:
				if _current_fire_timer >= burst_sequence_delay:
					_burst_wait_for_sequence_start = false
					_current_fire_timer = 0.0
					
					if _burst_current_sequence_count + 1 > burst_total_sequences:
						_set_state(AttackState.STATE_COOLDOWN_AFTER_BURST_ATTACK)
						return
					else:
						_burst_current_sequence_count += 1
						_fire_projectile_towards_target(get_player_position())
						_burst_current_bullet_count = 1
			else:
				if _burst_current_bullet_count < burst_bullets_per_sequence:
					if _current_fire_timer >= burst_bullet_delay:
						_fire_projectile_towards_target(get_player_position())
						_burst_current_bullet_count += 1
						_current_fire_timer = 0.0
				else:
					_burst_current_sequence_count += 1
					_burst_wait_for_sequence_start = true
					_current_fire_timer = 0.0
		AttackState.STATE_BARRAGE_BURST:
			_current_fire_timer += delta

			if _barrage_burst_waiting_for_delay:
				if _current_fire_timer >= barrage_burst_sequence_delay:
					_current_fire_timer = 0.0
					_barrage_burst_waiting_for_delay = false

					if _barrage_burst_is_player_burst:
						_barrage_burst_is_player_burst = false
						_barrage_burst_current_bullet_in_burst = 0
						_fire_projectile_towards_target(marker2d_7.global_position)
						_fire_projectile_towards_target(marker2d_5.global_position)
						_barrage_burst_current_bullet_in_burst += 1
					else:
						_barrage_burst_is_player_burst = true
						_barrage_burst_current_bullet_in_burst = 0
						
						if _barrage_burst_current_sequence_repeat + 1 > barrage_burst_total_sequences:
							_set_state(AttackState.STATE_COOLDOWN_AFTER_BARRAGE_BURST)
							return
						else:
							_barrage_burst_current_sequence_repeat += 1
							_fire_projectile_towards_target(get_player_position())
							_barrage_burst_current_bullet_in_burst += 1
			else:
				if _barrage_burst_current_bullet_in_burst < barrage_burst_bullets_per_burst:
					if _current_fire_timer >= barrage_burst_bullet_delay:
						if _barrage_burst_is_player_burst:
							_fire_projectile_towards_target(get_player_position())
						else:
							_fire_projectile_towards_target(marker2d_7.global_position)
							_fire_projectile_towards_target(marker2d_5.global_position)
						_barrage_burst_current_bullet_in_burst += 1
						_current_fire_timer = 0.0
				else:
					_barrage_burst_waiting_for_delay = true
					_current_fire_timer = 0.0
		_:
			pass

func _on_attack_phase_transition() -> void:
	match _current_attack_state:
		AttackState.STATE_COOLDOWN_AFTER_BARRAGE:
			_set_state(AttackState.STATE_PATTERN1_ACTIVE)
		AttackState.STATE_COOLDOWN_AFTER_PATTERN_PHASE:
			_set_state(AttackState.STATE_BURST_ATTACK)
		AttackState.STATE_COOLDOWN_AFTER_BURST_ATTACK:
			_set_state(AttackState.STATE_BARRAGE_BURST)
		AttackState.STATE_COOLDOWN_AFTER_BARRAGE_BURST:
			_set_state(AttackState.STATE_BARRAGE_ACTIVE)
		AttackState.STATE_COOLDOWN_ENRAGED_BARRAGE:
			_set_state(AttackState.STATE_ENRAGED_BARRAGE_ACTIVE)
		_:
			pass 
			
func get_player_position() -> Vector2:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0].global_position
	return Vector2(0, 1)

func _fire_projectile_towards_target(target_position: Vector2) -> void:
	if not projectile_scene:
		return

	var projectile_instance = projectile_scene.instantiate()
	get_parent().add_child(projectile_instance)

	projectile_instance.global_position = projectile_origin.global_position

	var direction = (target_position - projectile_origin.global_position).normalized()
	if projectile_instance.has_method("set_direction"):
		projectile_instance.set_direction(direction)

func _fire_projectiles_towards_pattern_markers(pattern_node: Node2D) -> void:
	for child in pattern_node.get_children():
		if child is Marker2D:
			_fire_projectile_towards_target(child.global_position)
