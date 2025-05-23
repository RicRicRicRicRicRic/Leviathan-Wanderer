# scyphozoa_rex_boss.gd
extends "res://scripts/Utility/Interpolate.gd"

@onready var visuals: Node2D = $Node2D_visuals
@onready var timer: Timer = $Timer
@onready var projectile_origin: Marker2D = $Node2D_visuals/Sprite2D_pupil/Marker2D_projectile
@export var projectile_scene: PackedScene = preload("res://scene/enemyscene/ScyphozoaRex-boss/scyphozoa_rex_projectile.tscn")

var hover_amplitude: float = -0.5
var hover_speed: float = 0.75

@export var barrage_active_duration: float = 10.0
@export var barrage_cooldown_duration: float = 3.0
@export var fire_rate_interval: float = 0.1 

var _time_elapsed: float = 0.0
var _is_firing_barrage: bool = false
var _current_fire_timer: float = 0.0

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position
	add_to_group("boss")

	randomize()

	timer.timeout.connect(_on_barrage_phase_transition)
	timer.wait_time = barrage_cooldown_duration
	timer.start()

func _physics_process(delta: float) -> void:
	previous_position = global_position

	_time_elapsed += delta
	var hover_offset_y: float = sin(_time_elapsed * hover_speed) * hover_amplitude
	global_position.y += hover_offset_y

	if _is_firing_barrage:
		_current_fire_timer += delta
		if _current_fire_timer >= fire_rate_interval: 
			_current_fire_timer = 0.0
			_fire_projectile()

func _on_barrage_phase_transition() -> void:
	_is_firing_barrage = not _is_firing_barrage

	if _is_firing_barrage:
		timer.wait_time = barrage_active_duration
		_current_fire_timer = 0.0
	else:
		timer.wait_time = barrage_cooldown_duration

	timer.start()

func _fire_projectile() -> void:
	if not projectile_scene:
		return

	var projectile_instance = projectile_scene.instantiate()
	get_parent().add_child(projectile_instance)

	projectile_instance.global_position = projectile_origin.global_position

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player_node = players[0]
		var direction_to_player = (player_node.global_position - projectile_origin.global_position).normalized()
		if projectile_instance.has_method("set_direction"):
			projectile_instance.set_direction(direction_to_player)
	else:
		if projectile_instance.has_method("set_direction"):
			projectile_instance.set_direction(Vector2(0, 1).normalized())
