# echinus_deus_boss.gd
extends CharacterBody2D

@onready var visuals: Node2D = $Node2D_visuals
@onready var timer: Timer = $Timer
@onready var marker1: Marker2D = $Node2D_visuals/Sprite2D_thorns/Marker2D
@onready var marker2: Marker2D = $Node2D_visuals/Sprite2D_thorns/Marker2D2
@onready var marker3: Marker2D = $Node2D_visuals/Sprite2D_thorns/Marker2D3
@onready var marker4: Marker2D = $Node2D_visuals/Sprite2D_thorns/Marker2D4
@onready var sprite_thorns: Sprite2D = $Node2D_visuals/Sprite2D_thorns
@export var projectile_scene: PackedScene = preload("res://scene/enemyscene/EchinusDeus_boss/boss_proj_urchin.tscn")
@export var carcass: PackedScene = preload("res://scene/enemyscene/EchinusDeus_boss/echinus_deus_carcass.tscn")

@export var rotation_speed: float = 0.25
@export var attack_rotation_speed: float = 1.5 
@export var alternating_rotation_speed: float = -2.0 
@export var alternating_clockwise_rotation_speed: float = 2.0 

@export var marker_barrage_fire_rate: float = 0.075
@export var marker_barrage_duration: float = 15.0

@export var alternating_barrage_fire_rate: float = 0.075
@export var alternating_sub_phase_duration: float = 6.0 

@export var urchin_scene: PackedScene = preload("res://scene/enemyscene/urchin/urchin.tscn") 
@export var urchins_to_summon_per_marker: int = 3 
@export var summon_delay_per_urchin: float = 0.2 
@export var summon_rotation_speed: float = 0.75 

@export var rotating_barrage_rotation_speed: float = 5.0 
@export var rotating_barrage_fire_rate: float = 0.075 
@export var rotating_barrage_barrage_duration: float = 1.0 
@export var rotating_barrage_pause_duration: float = 0.5

var max_health: float = 40000.0
var current_health: float = max_health
var is_enraged: bool = false 

signal health_changed(new_health_percent: float)
signal boss_defeated 

enum AttackState {
	STATE_IDLE, 
	STATE_MARKER_BARRAGE,
	STATE_COOLDOWN_AFTER_MARKER_BARRAGE,
	STATE_ALTERNATING_BARRAGE_PART1, 
	STATE_ALTERNATING_BARRAGE_PART2, 
	STATE_COOLDOWN_AFTER_ALTERNATING_BARRAGE,
	STATE_SUMMON_URCHINS, 
	STATE_COOLDOWN_AFTER_SUMMON,
	STATE_ROTATING_BARRAGE_ROTATE_TO_TARGET, 
	STATE_ROTATING_BARRAGE_FIRING,           
	STATE_ROTATING_BARRAGE_PAUSE,            
	STATE_COOLDOWN_AFTER_ROTATING_BARRAGE    
}

var _current_attack_state: AttackState = AttackState.STATE_IDLE
var _time_in_current_phase: float = 0.0
var _current_fire_timer: float = 0.0
var _current_visual_rotation_speed: float = 0.0 

var _current_summon_marker_index: int = 0
var _current_urchin_summon_count: int = 0
var _summon_fire_timer: float = 0.0

var _rotation_target_angles: Array[float] = [
	deg_to_rad(45), 
	deg_to_rad(90), 
	deg_to_rad(135), 
	deg_to_rad(180), 
	deg_to_rad(225),
	deg_to_rad(270),
	deg_to_rad(315),
	deg_to_rad(360),
]
var _current_rotation_step_index: int = 0
var _target_rotation: float = 0.0 
const ROTATION_TOLERANCE: float = 0.01 

func _ready() -> void:
	add_to_group("boss")
	add_to_group("enemy")

	randomize()

	timer.timeout.connect(_on_attack_phase_transition)
	
	var room_node = get_parent()
	if room_node and room_node.has_signal("boss_ready_for_attack"):
		room_node.boss_ready_for_attack.connect(_on_room_boss_ready_for_attack)

	_current_visual_rotation_speed = rotation_speed

func take_damage(amount: float) -> void:
	current_health -= amount
	health_changed.emit(current_health / max_health * 100.0)
	if current_health <= 0:
		call_deferred("_deferred_death")

func _deferred_death() -> void:
	boss_defeated.emit() 
	if carcass:
		var carcass_instance = carcass.instantiate()
		get_parent().add_child(carcass_instance)
		carcass_instance.global_position = global_position
	queue_free()

func _on_room_boss_ready_for_attack() -> void:
	_set_state(AttackState.STATE_MARKER_BARRAGE)

func _set_state(new_state: AttackState) -> void:
	_current_attack_state = new_state
	_current_fire_timer = 0.0
	_time_in_current_phase = 0.0 
	timer.stop()

	match _current_attack_state:
		AttackState.STATE_IDLE:
			_current_visual_rotation_speed = rotation_speed
			pass
		AttackState.STATE_MARKER_BARRAGE:
			_current_visual_rotation_speed = attack_rotation_speed
			pass
		AttackState.STATE_COOLDOWN_AFTER_MARKER_BARRAGE:
			_current_visual_rotation_speed = rotation_speed
			timer.start()
		AttackState.STATE_ALTERNATING_BARRAGE_PART1:
			_current_visual_rotation_speed = alternating_clockwise_rotation_speed
			timer.wait_time = alternating_sub_phase_duration
			timer.start()
		AttackState.STATE_ALTERNATING_BARRAGE_PART2:
			_current_visual_rotation_speed = alternating_rotation_speed
			timer.wait_time = alternating_sub_phase_duration
			timer.start()
		AttackState.STATE_COOLDOWN_AFTER_ALTERNATING_BARRAGE:
			_current_visual_rotation_speed = rotation_speed
			timer.start()
		AttackState.STATE_SUMMON_URCHINS:
			_current_visual_rotation_speed = summon_rotation_speed
			_current_summon_marker_index = 0
			_current_urchin_summon_count = 0
			_summon_fire_timer = 0.0 
			pass 
		AttackState.STATE_COOLDOWN_AFTER_SUMMON:
			_current_visual_rotation_speed = rotation_speed
			timer.start() 
		AttackState.STATE_ROTATING_BARRAGE_ROTATE_TO_TARGET:
			_current_visual_rotation_speed = rotating_barrage_rotation_speed
			if _current_rotation_step_index < _rotation_target_angles.size():
				_target_rotation = _rotation_target_angles[_current_rotation_step_index]
			else:
				_set_state(AttackState.STATE_COOLDOWN_AFTER_ROTATING_BARRAGE)
		AttackState.STATE_ROTATING_BARRAGE_FIRING:
			_current_visual_rotation_speed = 0.0 
			timer.wait_time = rotating_barrage_barrage_duration
			timer.start()
		AttackState.STATE_ROTATING_BARRAGE_PAUSE:
			_current_visual_rotation_speed = rotation_speed 
			timer.wait_time = rotating_barrage_pause_duration
			timer.start()
		AttackState.STATE_COOLDOWN_AFTER_ROTATING_BARRAGE:
			_current_visual_rotation_speed = rotation_speed
			timer.start() 
		_ : 
			pass

func _physics_process(delta: float) -> void:
	if sprite_thorns:
		match _current_attack_state:
			AttackState.STATE_ROTATING_BARRAGE_ROTATE_TO_TARGET:
				sprite_thorns.rotation = lerp_angle(sprite_thorns.rotation, _target_rotation, delta * _current_visual_rotation_speed)
				if abs(fmod(sprite_thorns.rotation - _target_rotation + PI, PI * 2) - PI) < ROTATION_TOLERANCE:
					_set_state(AttackState.STATE_ROTATING_BARRAGE_FIRING)
			_ :
				sprite_thorns.rotation += _current_visual_rotation_speed * delta

	match _current_attack_state:
		AttackState.STATE_IDLE:
			pass
		AttackState.STATE_MARKER_BARRAGE:
			_time_in_current_phase += delta
			_current_fire_timer += delta

			if _current_fire_timer >= marker_barrage_fire_rate:
				_current_fire_timer = 0.0
				_fire_projectiles_outward_from_markers()

			if _time_in_current_phase >= marker_barrage_duration:
				_set_state(AttackState.STATE_COOLDOWN_AFTER_MARKER_BARRAGE)
		AttackState.STATE_COOLDOWN_AFTER_MARKER_BARRAGE:
			pass
		AttackState.STATE_ALTERNATING_BARRAGE_PART1:
			_time_in_current_phase += delta 
			_current_fire_timer += delta

			if _current_fire_timer >= alternating_barrage_fire_rate:
				_current_fire_timer = 0.0
				_fire_projectiles_outward_from_specific_markers([marker1, marker4])
		AttackState.STATE_ALTERNATING_BARRAGE_PART2:
			_time_in_current_phase += delta 
			_current_fire_timer += delta

			if _current_fire_timer >= alternating_barrage_fire_rate:
				_current_fire_timer = 0.0
				_fire_projectiles_outward_from_specific_markers([marker3, marker2])
		AttackState.STATE_COOLDOWN_AFTER_ALTERNATING_BARRAGE:
			pass
		AttackState.STATE_SUMMON_URCHINS:
			var markers = [marker1, marker2, marker3, marker4]
			if _current_summon_marker_index < markers.size():
				var current_marker = markers[_current_summon_marker_index]
				
				_summon_fire_timer += delta

				if _current_urchin_summon_count < urchins_to_summon_per_marker:
					if _summon_fire_timer >= summon_delay_per_urchin:
						if current_marker:
							_summon_urchin_at_position(current_marker.global_position)
						_current_urchin_summon_count += 1
						_summon_fire_timer = 0.0
				else:
					_current_summon_marker_index += 1
					_current_urchin_summon_count = 0
					_summon_fire_timer = 0.0 
				
				if _current_summon_marker_index >= markers.size():
					_set_state(AttackState.STATE_COOLDOWN_AFTER_SUMMON)
			else:
				_set_state(AttackState.STATE_COOLDOWN_AFTER_SUMMON)
		AttackState.STATE_COOLDOWN_AFTER_SUMMON:
			pass
		AttackState.STATE_ROTATING_BARRAGE_ROTATE_TO_TARGET:
			pass
		AttackState.STATE_ROTATING_BARRAGE_FIRING:
			_current_fire_timer += delta
			if _current_fire_timer >= rotating_barrage_fire_rate:
				_current_fire_timer = 0.0
				_fire_projectiles_outward_from_markers() 
		AttackState.STATE_ROTATING_BARRAGE_PAUSE:
			pass
		AttackState.STATE_COOLDOWN_AFTER_ROTATING_BARRAGE:
			pass
		_ :
			pass

func _on_attack_phase_transition() -> void:
	match _current_attack_state:
		AttackState.STATE_COOLDOWN_AFTER_MARKER_BARRAGE:
			_set_state(AttackState.STATE_ALTERNATING_BARRAGE_PART1)
		AttackState.STATE_ALTERNATING_BARRAGE_PART1:
			_set_state(AttackState.STATE_ALTERNATING_BARRAGE_PART2)
		AttackState.STATE_ALTERNATING_BARRAGE_PART2:
			_set_state(AttackState.STATE_COOLDOWN_AFTER_ALTERNATING_BARRAGE)
		AttackState.STATE_COOLDOWN_AFTER_ALTERNATING_BARRAGE:
			_set_state(AttackState.STATE_SUMMON_URCHINS)
		AttackState.STATE_COOLDOWN_AFTER_SUMMON:
			_current_rotation_step_index = 0 
			_set_state(AttackState.STATE_ROTATING_BARRAGE_ROTATE_TO_TARGET)
		
		AttackState.STATE_ROTATING_BARRAGE_FIRING:
			_set_state(AttackState.STATE_ROTATING_BARRAGE_PAUSE)
		AttackState.STATE_ROTATING_BARRAGE_PAUSE:
			_current_rotation_step_index += 1
			if _current_rotation_step_index < _rotation_target_angles.size():
				_set_state(AttackState.STATE_ROTATING_BARRAGE_ROTATE_TO_TARGET)
			else:
				_set_state(AttackState.STATE_COOLDOWN_AFTER_ROTATING_BARRAGE)
		AttackState.STATE_COOLDOWN_AFTER_ROTATING_BARRAGE:
			_set_state(AttackState.STATE_MARKER_BARRAGE)
		_ :
			pass 
			
func get_player_position() -> Vector2:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0].global_position
	return Vector2(0, 0)

func _spawn_and_fire_projectile(origin_pos: Vector2, direction_vector: Vector2) -> void:
	if not projectile_scene:
		return

	var projectile_instance = projectile_scene.instantiate()
	get_parent().add_child(projectile_instance)

	projectile_instance.global_position = origin_pos

	if projectile_instance.has_method("set_initial_direction"):
		projectile_instance.call_deferred("set_initial_direction", direction_vector)

	projectile_instance.set_deferred("rotation", direction_vector.angle())

func _fire_projectiles_outward_from_markers() -> void:
	var markers = [marker1, marker2, marker3, marker4]
	
	for marker in markers:
		if marker:
			var direction_vector = (marker.global_position - global_position).normalized()
			_spawn_and_fire_projectile(marker.global_position, direction_vector)

func _fire_projectiles_outward_from_specific_markers(markers_to_fire_from: Array[Marker2D]) -> void:
	for marker in markers_to_fire_from:
		if marker:
			var direction_vector = (marker.global_position - global_position).normalized()
			_spawn_and_fire_projectile(marker.global_position, direction_vector)

func _summon_urchin_at_position(spawn_pos: Vector2) -> void:
	if not urchin_scene:
		return
	
	var urchin_instance = urchin_scene.instantiate()
	get_parent().add_child(urchin_instance)
	urchin_instance.global_position = spawn_pos
