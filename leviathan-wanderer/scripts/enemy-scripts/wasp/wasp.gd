# wasp.gd
extends CharacterBody2D

@export var max_health: int = 600
@export var stinger_scene: PackedScene = preload("res://scene/enemyscene/wasp/stinger.tscn")
@export var follow_speed: float = 200.0
@export var min_follow_distance: float = 350.0
@export var stop_follow_distance: float = 400.0
@export var acceleration_rate: float = 500.0
@export var deceleration_rate: float = 800.0
@export var avoidance_speed_multiplier: float = 5
@export var max_dodge_distance: float = 75.0

var health: int
var is_dying: bool = false
var _player_node: Node = null
var death_y_position: float = 0.0
@export var fall_distance_to_free: float = 1750.0
var _avoid_direction: Vector2 = Vector2.ZERO
var _dodge_start_position: Vector2 = Vector2.ZERO
var _is_dodging: bool = false

@onready var visuals: Node2D = $Node2D
@onready var marker: Marker2D =$Node2D/Marker2D
@onready var wing_left: AnimatedSprite2D = $Node2D/AnimatedSprite2D_wings_R
@onready var wing_right: AnimatedSprite2D = $Node2D/AnimatedSprite2D_wings_L
@onready var eyes: Sprite2D = $Node2D/Sprite2D_eyes
@onready var abdomen: Sprite2D = $Node2D/Sprite2D_abdomen
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var hp_bar: Control = $Control
@onready var timer: Timer =$Timer
@onready var detect_obstacle: RayCast2D = $RayCast2D_obstacle
@onready var detect_floor: RayCast2D = $RayCast2D_floor
@onready var area2D: Area2D = $Area2D

func _ready():
	add_to_group("enemy")
	health = max_health
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	_player_node = get_tree().get_first_node_in_group("player")

	detect_obstacle.add_exception(self)
	if _player_node:
		detect_obstacle.add_exception(_player_node)

	area2D.body_entered.connect(_on_Area2D_body_entered)

func _physics_process(delta: float):
	if is_dying:
		var gravity: float = 2000.0
		velocity.y += gravity * delta
		velocity.x += 0
		move_and_slide()
		if global_position.y - death_y_position >= fall_distance_to_free:
			queue_free()
		return

	var player_follow_velocity = Vector2.ZERO
	if _player_node and is_instance_valid(_player_node):
		var direction_to_player = (_player_node.global_position - global_position)
		var distance_to_player = direction_to_player.length()

		detect_obstacle.target_position = detect_obstacle.to_local(_player_node.global_position)
		detect_obstacle.force_raycast_update()

		if distance_to_player > stop_follow_distance:
			player_follow_velocity = direction_to_player.normalized() * follow_speed
		elif distance_to_player < min_follow_distance:
			player_follow_velocity = -direction_to_player.normalized() * follow_speed
			player_follow_velocity = player_follow_velocity.limit_length(follow_speed)

	var final_target_velocity = player_follow_velocity

	if _is_dodging:
		var dodge_progress = (global_position - _dodge_start_position).length()
		if dodge_progress < max_dodge_distance:
			var avoidance_velocity = _avoid_direction * follow_speed * avoidance_speed_multiplier
			final_target_velocity += avoidance_velocity
			final_target_velocity = final_target_velocity.limit_length(follow_speed * avoidance_speed_multiplier)
		else:
			_is_dodging = false
			_avoid_direction = Vector2.ZERO


	if detect_floor.is_colliding():
		final_target_velocity.y = -follow_speed

	var current_speed = velocity.length()
	var target_speed = final_target_velocity.length()

	if target_speed > current_speed:
		velocity = velocity.move_toward(final_target_velocity, acceleration_rate * delta)
	else:
		velocity = velocity.move_toward(final_target_velocity, deceleration_rate * delta)

	move_and_slide()

	if _player_node and is_instance_valid(_player_node):
		if _player_node.global_position.x < global_position.x:
			visuals.scale.x = -abs(visuals.scale.x)
			collision_polygon.scale.x = -abs(collision_polygon.scale.x)
		else:
			visuals.scale.x = abs(visuals.scale.x)
			collision_polygon.scale.x = abs(collision_polygon.scale.x)


func take_damage(amount: float) -> void:
	health -= int(amount)
	if health <= 0 and not is_dying:
		is_dying = true
		hp_bar.queue_free()
		collision_polygon.set_deferred("disabled", true)
		velocity.y = 100
		velocity.x = 0
		wing_left.stop()
		wing_right.stop()
		wing_left.self_modulate = Color(1, 1, 1)
		wing_right.self_modulate = Color(1, 1, 1)
		eyes.self_modulate = Color(1, 1, 1)
		abdomen.self_modulate = Color(1, 1, 1)
		death_y_position = global_position.y

func _on_timer_timeout() -> void:
	if _player_node and is_instance_valid(_player_node) and not is_dying:
		if not detect_obstacle.is_colliding():
			shoot_stinger()
	timer.start()

func shoot_stinger() -> void:
	if stinger_scene == null:
		return
	var stinger_instance = stinger_scene.instantiate() as RigidBody2D
	if stinger_instance == null:
		return
	stinger_instance.global_position = marker.global_position
	stinger_instance._player_node = _player_node
	var direction = (_player_node.global_position - marker.global_position).normalized()
	stinger_instance.rotation = direction.angle()
	get_tree().current_scene.add_child(stinger_instance)

func _on_Area2D_body_entered(body: Node2D) -> void:
	if body.is_in_group("projectiles") or body.is_in_group("laser"):
		var direction_from_body = (global_position - body.global_position)
		
		_avoid_direction = direction_from_body.normalized()
			
		_dodge_start_position = global_position
		_is_dodging = true
	elif body == self or body == _player_node:
		return
