# termite.gd
extends "res://scripts/Utility/Interpolate.gd"

@export var rotation_speed: float = 3.0
@export var movement_speed: float = 275.0
@export var rotation_stop_threshold_degrees: float = 45.0
@export var avoidance_turn_angle_degrees: float = 15.0
@export var fast_rotation_speed: float = 10.0
@export var max_health: int = 150
@export var knockback_strength: float = 1500.0
@export var health: int

@onready var visuals: Node2D = $Node2D
@onready var _collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var ray_left: RayCast2D = $Node2D/Node2D_raycasts/RayCast2D_Left
@onready var ray_right: RayCast2D = $Node2D/Node2D_raycasts/RayCast2D_Right
@onready var ray_forward: RayCast2D = $RayCast2D_Forward
@onready var death_particles: GPUParticles2D = $Node2D/GPUParticles2D
@onready var death_particles_circle: GPUParticles2D = $Node2D/GPUParticles2D_circle
@onready var explostion_area: Area2D = $Area2D
@onready var suicide_area: Area2D = $Area2D_suicide
@onready var hp_bar: Control = $Control
@onready var body_anim: AnimatedSprite2D = $Node2D/AnimatedSprite2D_body
@onready var tail_anim: AnimatedSprite2D = $Node2D/AnimatedSprite2D_body/AnimatedSprite2D_tail
@onready var time_to_delete: Timer = $Timer

var player_node: Node2D = null
var _is_committing_avoidance_turn: bool = false
var _avoidance_target_angle: float = 0.0
var _last_avoidance_turn_direction_factor: float = 0.0
var _was_detecting_side_obstacles_last_frame: bool = false
var is_dying: bool = false
var direction: int = -1
var damage: int = 45

var _explosion_collision_shape: CollisionShape2D = null
var _initial_explosion_scale: Vector2 = Vector2.ONE
var _explosion_tween_duration: float = 0.225

signal died

func _ready():
	interp_visuals = visuals
	previous_position = global_position
	add_to_group("enemy")
	health = max_health
	player_node = get_tree().get_first_node_in_group("player")
	ray_left.enabled = true
	ray_right.enabled = true
	ray_forward.enabled = true
	if player_node:
		ray_forward.add_exception(player_node)
	for node in get_tree().get_nodes_in_group("enemy"):
		ray_forward.add_exception(node)
	explostion_area.body_entered.connect(_on_DamageArea_body_entered)
	suicide_area.body_entered.connect(_on_SuicideArea_body_entered)
	explostion_area.set_deferred("disabled", true)
	explostion_area.monitoring = false
	suicide_area.set_deferred("disabled", true)
	suicide_area.monitoring = false
	time_to_delete.timeout.connect(_on_time_to_delete_timeout)
	for child in explostion_area.get_children():
		if child is CollisionShape2D:
			_explosion_collision_shape = child
			_initial_explosion_scale = child.scale
			break

func _physics_process(delta: float):
	previous_position = global_position
	if is_dying:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player_node:
		var direction_to_player: Vector2 = (player_node.global_position - global_position).normalized()
		var target_angle_to_player: float = direction_to_player.angle() + PI / 2.0

		ray_forward.target_position = player_node.global_position - ray_forward.global_position
		ray_forward.force_raycast_update()

		var current_visual_rotation = visuals.rotation
		var final_target_angle: float
		var current_movement_speed = movement_speed
		var movement_direction: Vector2
		var current_rotation_speed_applied = rotation_speed
		var left_colliding = ray_left.is_colliding()
		var right_colliding = ray_right.is_colliding()
		var forward_colliding = ray_forward.is_colliding()
		var is_currently_detecting_side_obstacles = left_colliding or right_colliding

		if forward_colliding:
			suicide_area.set_deferred("disabled", true)
			suicide_area.monitoring = false
		else:
			suicide_area.set_deferred("disabled", false)
			suicide_area.monitoring = true

		var determined_turn_direction_factor: float = 0.0
		if is_currently_detecting_side_obstacles:
			if left_colliding and right_colliding:
				var dist_left = INF
				if ray_left.get_collider(): dist_left = (ray_left.get_collision_point() - ray_left.global_position).length()
				var dist_right = INF
				if ray_right.get_collider(): dist_right = (ray_right.get_collision_point() - ray_right.global_position).length()
				determined_turn_direction_factor = 1.0 if dist_left < dist_right else -1.0
			elif left_colliding:
				determined_turn_direction_factor = 1.0
			elif right_colliding:
				determined_turn_direction_factor = -1.0

		if forward_colliding:
			_is_committing_avoidance_turn = false
			movement_direction = -visuals.transform.y.normalized()
			current_movement_speed = movement_speed
			final_target_angle = current_visual_rotation
			current_rotation_speed_applied = rotation_speed

			if is_currently_detecting_side_obstacles:
				current_rotation_speed_applied = fast_rotation_speed
				final_target_angle = current_visual_rotation + (determined_turn_direction_factor * current_rotation_speed_applied * delta)
				_last_avoidance_turn_direction_factor = determined_turn_direction_factor

		elif _is_committing_avoidance_turn:
			var angular_deviation_from_avoidance_target = wrapf(_avoidance_target_angle - current_visual_rotation, -PI, PI)
			if abs(angular_deviation_from_avoidance_target) < deg_to_rad(2.0):
				_is_committing_avoidance_turn = false
				movement_direction = direction_to_player
				current_movement_speed = movement_speed
				current_rotation_speed_applied = rotation_speed
				var angular_deviation_to_player = wrapf(target_angle_to_player - current_visual_rotation, -PI, PI)
				if abs(angular_deviation_to_player) > deg_to_rad(rotation_stop_threshold_degrees):
					current_movement_speed = 0.0
				final_target_angle = target_angle_to_player
			else:
				final_target_angle = _avoidance_target_angle
				movement_direction = -visuals.transform.y.normalized()
				current_movement_speed = movement_speed
				current_rotation_speed_applied = rotation_speed

		else:
			if is_currently_detecting_side_obstacles:
				_is_committing_avoidance_turn = false
				movement_direction = -visuals.transform.y.normalized()
				current_movement_speed = movement_speed
				current_rotation_speed_applied = fast_rotation_speed
				final_target_angle = current_visual_rotation + (determined_turn_direction_factor * current_rotation_speed_applied * delta)
				_last_avoidance_turn_direction_factor = determined_turn_direction_factor
			elif _was_detecting_side_obstacles_last_frame and not is_currently_detecting_side_obstacles:
				_is_committing_avoidance_turn = true
				_avoidance_target_angle = current_visual_rotation + (_last_avoidance_turn_direction_factor * deg_to_rad(avoidance_turn_angle_degrees))
				final_target_angle = _avoidance_target_angle
				movement_direction = -visuals.transform.y.normalized()
				current_movement_speed = movement_speed
				current_rotation_speed_applied = rotation_speed
			else:
				movement_direction = direction_to_player
				current_movement_speed = movement_speed
				current_rotation_speed_applied = rotation_speed
				var angular_deviation_to_player = wrapf(target_angle_to_player - current_visual_rotation, -PI, PI)
				var rotation_threshold_radians = deg_to_rad(rotation_stop_threshold_degrees)
				if abs(angular_deviation_to_player) > rotation_threshold_radians:
					current_movement_speed = 0.0
				final_target_angle = target_angle_to_player

		visuals.rotation = lerp_angle(current_visual_rotation, final_target_angle, delta * current_rotation_speed_applied)
		_collision_polygon.rotation = lerp_angle(_collision_polygon.rotation, final_target_angle, delta * current_rotation_speed_applied)
		velocity = movement_direction * current_movement_speed
		move_and_slide()
		_was_detecting_side_obstacles_last_frame = is_currently_detecting_side_obstacles

func take_damage(amount: float) -> void:
	health -= int(amount)
	if health <= 0 and not is_dying:
		is_dying = true
		velocity = Vector2.ZERO
		_collision_polygon.set_deferred("disabled", true)
		body_anim.visible = false
		tail_anim.visible = false
		death_particles.emitting = true
		death_particles_circle.emitting = true
		hp_bar.queue_free()

		emit_signal("died")

		if _explosion_collision_shape:
			_explosion_collision_shape.scale = Vector2(0.1, 0.1)
			explostion_area.monitoring = true
			explostion_area.set_deferred("disabled", false)
			var tween = create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_QUAD)
			tween.tween_property(_explosion_collision_shape, "scale", _initial_explosion_scale, _explosion_tween_duration)
			tween.tween_callback(Callable(self, "_on_explosion_scale_finished"))
		else:
			queue_free()

func _on_DamageArea_body_entered(body) -> void:
	if body.is_in_group("player") and explostion_area.monitoring:
		var diff: Vector2 = body.global_position - global_position
		var knock_dir: Vector2
		if diff.length() > 0:
			knock_dir = diff.normalized()
		else:
			knock_dir = Vector2(-direction, 0)
		var knockback_force: Vector2 = knock_dir * knockback_strength
		body.take_damage(damage)
		body.knockback(knockback_force)
		explostion_area.set_deferred("monitoring", false)
		explostion_area.set_deferred("disabled", true)

func _on_SuicideArea_body_entered(body) -> void:
	if body.is_in_group("player"):
		take_damage(max_health)
		suicide_area.queue_free()
		
func _on_explosion_scale_finished() -> void:
	explostion_area.queue_free()
	time_to_delete.start()

func _on_time_to_delete_timeout() -> void:
	queue_free()
