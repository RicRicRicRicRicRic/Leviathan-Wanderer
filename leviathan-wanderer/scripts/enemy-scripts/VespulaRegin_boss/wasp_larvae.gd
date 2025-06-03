# wasp_larvae.gd
extends "res://scripts/Utility/Interpolate.gd"

@export var max_health: int = 80
@export var fall_distance_to_free: float = 1500.0
@export var larv_proj: PackedScene = preload("res://scene/enemyscene/VespulaRegin-boss/larvae_proj.tscn")
@export var shoot_radius: float = 500.0
@export var follow_speed: float = 150.0
@export var stop_follow_distance: float = 450.0
@export var acceleration_rate: float = 300.0
@export var deceleration_rate: float = 500.0
@export var vertical_offset_above_player: float = 125

var health: int
var is_dying: bool = false
var death_y_position: float = 0.0
var _player_node: Node = null
var _is_shooting_active: bool = false

@onready var visuals: Node2D = $Node2D
@onready var collider: CollisionPolygon2D = $CollisionPolygon2D
@onready var wing_left: AnimatedSprite2D = $Node2D/AnimatedSprite2D_wingL
@onready var wing_right: AnimatedSprite2D = $Node2D/AnimatedSprite2D_wingR
@onready var proj_Timer: Timer = $Proj_Timer

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	_player_node = get_tree().get_first_node_in_group("player")
	proj_Timer.timeout.connect(_proj_Timer_timeout)
	interp_visuals = visuals
	previous_position = global_position
	var boss_node = get_tree().get_first_node_in_group("boss")
	if boss_node and is_instance_valid(boss_node):
		boss_node.boss_defeated.connect(_on_boss_defeated)

func _physics_process(delta: float) -> void:
	previous_position = global_position
	if is_dying:
		var gravity: float = 1000.0
		velocity.y += gravity * delta
		velocity.x = 0.0
		move_and_slide()
		if global_position.y - death_y_position >= fall_distance_to_free:
			queue_free()
		return

	var player_follow_velocity: Vector2 = Vector2.ZERO
	var final_target_velocity: Vector2 = Vector2.ZERO

	if _player_node and is_instance_valid(_player_node):
		var direction_to_player: Vector2 = (_player_node.global_position - global_position)
		var distance_to_player: float = direction_to_player.length()

		if distance_to_player > stop_follow_distance:
			player_follow_velocity.x = direction_to_player.normalized().x * follow_speed
		elif distance_to_player < stop_follow_distance - 50: 
			player_follow_velocity.x = -direction_to_player.normalized().x * (follow_speed * 0.5)
		else:
			player_follow_velocity.x = 0.0

		var target_y_position = _player_node.global_position.y - vertical_offset_above_player
		if global_position.y < target_y_position: 
			player_follow_velocity.y = follow_speed
		elif global_position.y > target_y_position + 20: 
			player_follow_velocity.y = -follow_speed * 0.5 
		else:
			player_follow_velocity.y = 0.0 

		final_target_velocity = player_follow_velocity

		var current_speed: float = velocity.length()
		var target_speed: float = final_target_velocity.length()

		if target_speed > current_speed:
			velocity = velocity.move_toward(final_target_velocity, acceleration_rate * delta)
		else:
			velocity = velocity.move_toward(final_target_velocity, deceleration_rate * delta)

		move_and_slide()

		if _player_node.global_position.x < global_position.x:
			visuals.scale.x = abs(visuals.scale.x)
			collider.scale.x = abs(collider.scale.x)
		else:
			visuals.scale.x = -abs(visuals.scale.x)
			collider.scale.x = -abs(collider.scale.x)

		var distance_to_player_for_shooting: float = global_position.distance_to(_player_node.global_position)

		if distance_to_player_for_shooting <= shoot_radius:
			if not _is_shooting_active:
				proj_Timer.start()
				_is_shooting_active = true
		else:
			if _is_shooting_active:
				proj_Timer.stop()
				_is_shooting_active = false


func take_damage(amount: float) -> void:
	health -= int(amount)
	health = max(0, health)

	if health <= 0 and not is_dying:
		is_dying = true
		if is_instance_valid(collider):
			collider.set_deferred("disabled", true)
		velocity.y = 100.0
		velocity.x = 0.0
		wing_left.stop()
		wing_right.stop()
		death_y_position = global_position.y
		proj_Timer.stop()
		_is_shooting_active = false

func _proj_Timer_timeout() -> void:
	if _player_node and is_instance_valid(_player_node) and not is_dying and _is_shooting_active:
		shoot_projectile()
	if _is_shooting_active:
		proj_Timer.start()

func shoot_projectile() -> void:
	if larv_proj == null:
		return
	var projectile_instance = larv_proj.instantiate()
	if projectile_instance == null:
		return

	projectile_instance.global_position = global_position
	if projectile_instance.has_method("set_target_player"):
		projectile_instance.set_target_player(_player_node)
	elif projectile_instance.has_node("TargetPlayer"):
		projectile_instance.get_node("TargetPlayer").target = _player_node.global_position

	var direction: Vector2 = (_player_node.global_position - global_position).normalized()
	projectile_instance.rotation = direction.angle()

	get_tree().current_scene.add_child(projectile_instance)

func _on_boss_defeated() -> void:
	if not is_dying:
		take_damage(health + 1)
