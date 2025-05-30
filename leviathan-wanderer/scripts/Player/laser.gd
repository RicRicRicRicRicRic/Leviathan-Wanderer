# laser.gd
extends Node2D

@onready var timer_laser: Timer = $Timer_laser
@onready var node_to_rotate: Node2D = $Node2D
@onready var laser_anim: AnimatedSprite2D = $Node2D/AnimatedSprite2D
@onready var laser_end: Marker2D = $Node2D/Marker2D
@onready var laser_area: Area2D = $Node2D/Area2D
@onready var laser_collision_shape: CollisionShape2D = $Node2D/Area2D/CollisionShape2D

@export var rotation_speed: float = 7.0
@export var damage_amount: int = 325
@export var continuous_damage_amount: int = 85
@export var continuous_damage_interval: float = 0.1
var laser_combo_value: int = 11 

var _player_laser_marker: Marker2D = null
signal laser_finished_firing

enum LaserState {
	CHARGING,
	ACTIVE,
	WEAKENING
}

var current_state: LaserState
var _enemies_burst_damaged: Array[Object]
var _continuous_damage_timer: float = 0.0
static var is_laser_active: bool = false

func _ready() -> void:
	if is_laser_active:
		queue_free()
		return
	add_to_group("laser")
	is_laser_active = true

	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		var wep_node = player_node.get_node_or_null("Node2D/WeaponSprite2D")
		if wep_node and wep_node.has_node("Marker2D_laser"):
			_player_laser_marker = wep_node.get_node("Marker2D_laser")


	_rotate_immediately_towards_mouse()
	current_state = LaserState.CHARGING
	laser_anim.play("laser_charge")
	laser_area.monitoring = false
	laser_collision_shape.disabled = true
	laser_anim.connect("animation_finished", Callable(self, "_on_laser_anim_finished"))
	timer_laser.connect("timeout", Callable(self, "_on_timer_timeout"))

	laser_area.connect("body_entered", Callable(self, "_on_laser_area_body_entered"))
	laser_area.connect("body_exited", Callable(self, "_on_laser_area_body_exited"))

func _physics_process(delta: float) -> void:
	if _player_laser_marker:
		global_position = _player_laser_marker.global_position
	_rotate_slowly_towards_mouse(delta)

	if current_state == LaserState.ACTIVE:
		_continuous_damage_timer += delta
		if _continuous_damage_timer >= continuous_damage_interval:
			_continuous_damage_timer = 0.0
			var player_node = get_tree().get_first_node_in_group("player") 
			for body in laser_area.get_overlapping_bodies():
				if body.is_in_group("enemy") and body.has_method("take_damage"):
					if _enemies_burst_damaged.has(body): 
						body.take_damage(continuous_damage_amount)
						if player_node and player_node.has_method("add_combo"):
							player_node.add_combo(laser_combo_value)


func _rotate_immediately_towards_mouse() -> void:
	var mouse_position = get_global_mouse_position()
	var laser_position = global_position
	var direction_vector = mouse_position - laser_position
	var target_angle = direction_vector.angle()
	node_to_rotate.rotation = target_angle

func _rotate_slowly_towards_mouse(delta: float) -> void:
	var mouse_position = get_global_mouse_position()
	var laser_position = global_position
	var direction_vector = mouse_position - laser_position
	var target_angle = direction_vector.angle()
	node_to_rotate.rotation = wrapf(
		lerp_angle(node_to_rotate.rotation, target_angle, delta * rotation_speed),
		-PI, PI
	)

func _on_laser_anim_finished() -> void:
	if current_state == LaserState.CHARGING:
		current_state = LaserState.ACTIVE
		timer_laser.start()
		laser_area.monitoring = true
		laser_collision_shape.disabled = false
		_enemies_burst_damaged.clear()
		_continuous_damage_timer = 0.0
	elif current_state == LaserState.WEAKENING:
		is_laser_active = false
		emit_signal("laser_finished_firing")
		queue_free()

func _on_timer_timeout() -> void:
	current_state = LaserState.WEAKENING
	laser_area.monitoring = false
	laser_collision_shape.disabled = true
	_enemies_burst_damaged.clear()
	laser_anim.play("laser_weaken")

func _on_laser_area_body_entered(body: Node2D) -> void:
	if current_state == LaserState.ACTIVE:
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			if not _enemies_burst_damaged.has(body):
				body.take_damage(damage_amount)
				_enemies_burst_damaged.append(body)
				var player_node = get_tree().get_first_node_in_group("player")
				if player_node and player_node.has_method("add_combo"):
					player_node.add_combo(laser_combo_value)


func _on_laser_area_body_exited(_body: Node2D) -> void:
	pass
