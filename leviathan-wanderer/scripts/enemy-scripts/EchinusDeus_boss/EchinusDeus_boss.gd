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

@export var marker_barrage_fire_rate: float = 0.2
@export var marker_barrage_duration: float = 5.0
@export var cooldown_duration_after_marker_barrage: float = 2.0

var max_health: float = 40000.0
var current_health: float = max_health
var is_enraged: bool = false 

signal health_changed(new_health_percent: float)
signal boss_defeated 

enum AttackState {
	STATE_IDLE, 
	STATE_MARKER_BARRAGE,
	STATE_COOLDOWN_AFTER_MARKER_BARRAGE
}

var _current_attack_state: AttackState = AttackState.STATE_IDLE
var _time_in_current_phase: float = 0.0
var _current_fire_timer: float = 0.0

func _ready() -> void:
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
			pass
		AttackState.STATE_MARKER_BARRAGE:
			pass
		AttackState.STATE_COOLDOWN_AFTER_MARKER_BARRAGE:
			timer.wait_time = cooldown_duration_after_marker_barrage
			timer.start()
		_ : 
			pass

func _physics_process(delta: float) -> void:
	if sprite_thorns:
		sprite_thorns.rotation += rotation_speed * delta

	match _current_attack_state:
		AttackState.STATE_IDLE:
			pass
		AttackState.STATE_MARKER_BARRAGE:
			_time_in_current_phase += delta
			_current_fire_timer += delta

			if _current_fire_timer >= marker_barrage_fire_rate:
				_current_fire_timer = 0.0
				_fire_projectiles_from_all_markers_towards_player()

			if _time_in_current_phase >= marker_barrage_duration:
				_set_state(AttackState.STATE_COOLDOWN_AFTER_MARKER_BARRAGE)
		AttackState.STATE_COOLDOWN_AFTER_MARKER_BARRAGE:
			pass
		_ :
			pass

func _on_attack_phase_transition() -> void:
	match _current_attack_state:
		AttackState.STATE_COOLDOWN_AFTER_MARKER_BARRAGE:
			_set_state(AttackState.STATE_MARKER_BARRAGE) 
		_ :
			pass 
			
func get_player_position() -> Vector2:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0].global_position
	return Vector2(0, 0)

func _fire_projectile_from_origin_to_target(origin_pos: Vector2, target_pos: Vector2) -> void:
	if not projectile_scene:
		return

	var projectile_instance = projectile_scene.instantiate()
	get_parent().add_child(projectile_instance)

	projectile_instance.global_position = origin_pos

	var direction = (target_pos - origin_pos).normalized()
	# CORRECTED: Call set_initial_direction
	if projectile_instance.has_method("set_initial_direction"):
		projectile_instance.set_initial_direction(direction)

func _fire_projectiles_from_all_markers_towards_player() -> void:
	var player_pos = get_player_position()
	
	if marker1:
		_fire_projectile_from_origin_to_target(marker1.global_position, player_pos)
	
	if marker2:
		_fire_projectile_from_origin_to_target(marker2.global_position, player_pos)

	if marker3:
		_fire_projectile_from_origin_to_target(marker3.global_position, player_pos)

	if marker4:
		_fire_projectile_from_origin_to_target(marker4.global_position, player_pos)
