#worm.gd
extends "res://scripts/Utility/Interpolate.gd"

@export var max_health: int = 900
@export var scan_radius: float = 3000.0
@export var noturn_radius: float = 300.0
@export var move_speed: float = 900.0
@export var move_speed_noturn: float = 700.0
@export var max_turn_angle: float = 200.0
@export var decel_rate: float = 1000.0
@export var spacing_frames: float = 3.5
@export var knockback_strength: float = 1500.0
@export var death_gravity: float = 600.0
@export var death_kick_min: float = 200.0
@export var death_kick_max: float = 500.0

@onready var hp_bar: Control = $Control
@onready var visuals: Node2D = $Node2D
@onready var head: AnimatedSprite2D = $Node2D/AnimatedSprite2D_head
@onready var body_main: Sprite2D = $Node2D/Node2D_segments/Sprite2D_body_main
@onready var body_1: Sprite2D = body_main.get_node("Sprite2D_body1")
@onready var body_2: Sprite2D = body_1.get_node("Sprite2D_body2")
@onready var body_3: Sprite2D = body_2.get_node("Sprite2D_body3")
@onready var body_4: Sprite2D = body_3.get_node("Sprite2D_body4")
@onready var body_5: Sprite2D = body_4.get_node("Sprite2D_body5")
@onready var body_6: Sprite2D = body_5.get_node("Sprite2D_body6")
@onready var body_7: Sprite2D = body_6.get_node("Sprite2D_body7")
@onready var tail: Sprite2D = body_7.get_node("Sprite2D_tail")

@onready var head_collider: CollisionShape2D = $CollisionShape2D_head
@onready var body_main_collider: CollisionShape2D = $CollisionShape2D_body_main
@onready var body1_collider: CollisionShape2D = $CollisionShape2D_body1
@onready var body2_collider: CollisionShape2D = $CollisionShape2D_body2
@onready var body3_collider: CollisionShape2D = $CollisionShape2D_body3
@onready var body4_collider: CollisionShape2D = $CollisionShape2D_body4
@onready var body5_collider: CollisionShape2D = $CollisionShape2D_body5
@onready var body6_collider: CollisionShape2D = $CollisionShape2D_body6
@onready var body7_collider: CollisionShape2D = $CollisionShape2D_body7
@onready var tail_collider: CollisionShape2D = $CollisionShape2D_tail

@onready var area2D_Damage: Area2D = $Area2D_Damage
@onready var ray: RayCast2D = head.get_node("RayCast2D")

var parts: Array[Sprite2D] = []
var segment_colliders: Array[CollisionShape2D] = []
var head_history: Array[Vector2] = []
var part_velocities: Array[Vector2] = []
var current_speed: float = 0.0
var is_dying: bool = false
var health: int = 0
var fade_timer: float = 0.0
var fade_duration: float = 3.0
var was_hitting_player: bool = false

# new flag to suppress exit animation right after execute
var skip_bite_exit: bool = false

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position
	parts = [body_main, body_1, body_2, body_3, body_4, body_5, body_6, body_7, tail]
	segment_colliders = [body_main_collider, body1_collider, body2_collider, body3_collider, body4_collider, body5_collider, body6_collider, body7_collider, tail_collider]
	var history_size: int = int((parts.size() + 1) * spacing_frames) + 2
	head_history.resize(history_size)
	for i in range(history_size):
		head_history[i] = global_position
	health = max_health
	current_speed = move_speed
	area2D_Damage.body_entered.connect(_on_DamageArea_body_entered)
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	previous_position = global_position
	if is_dying:
		_process_death(delta)
		return
	_handle_player_detection()
	_handle_movement(delta)

func _process_death(delta: float) -> void:
	var vel: Vector2 = part_velocities[0]
	vel.y += death_gravity * delta
	part_velocities[0] = vel
	head.global_position += vel * delta
	for i in range(parts.size()):
		var vel_i: Vector2 = part_velocities[i + 1]
		vel_i.y += death_gravity * delta
		part_velocities[i + 1] = vel_i
		parts[i].global_position += vel_i * delta
	fade_timer += delta
	var fade_ratio: float = clamp(1.0 - fade_timer / fade_duration, 0.0, 1.0)
	visuals.modulate.a = fade_ratio
	if fade_ratio <= 0.0:
		queue_free()

func _handle_player_detection() -> void:
	ray.force_raycast_update()
	var is_hitting: bool = ray.is_colliding() and ray.get_collider().is_in_group("player")
	if is_hitting and not was_hitting_player:
		head.play("bite_prep")
	elif not is_hitting and was_hitting_player:
		if not skip_bite_exit:
			head.play("bite_prep_exit")
		skip_bite_exit = false
	was_hitting_player = is_hitting

func _handle_movement(delta: float) -> void:
	var player_node: Node2D = get_tree().get_first_node_in_group("player")
	if player_node == null:
		return
	var to_player: Vector2 = player_node.global_position - global_position
	var dist: float = to_player.length()
	if dist > scan_radius:
		return
	if dist <= noturn_radius:
		if current_speed > move_speed_noturn:
			current_speed = max(current_speed - decel_rate * delta, move_speed_noturn)
		position += Vector2.RIGHT.rotated(rotation) * current_speed * delta
		_update_parts()
		return
	if current_speed < move_speed:
		current_speed = min(current_speed + decel_rate * delta, move_speed)
	var target_angle: float = to_player.angle()
	var angle_diff: float = wrapf(target_angle - rotation, -PI, PI)
	var max_step: float = deg_to_rad(max_turn_angle) * delta
	rotation += clamp(angle_diff, -max_step, max_step)
	position += Vector2.RIGHT.rotated(rotation) * current_speed * delta
	_update_parts()

func _update_parts() -> void:
	head_history.insert(0, global_position)
	var max_len: int = int((parts.size() + 1) * spacing_frames) + 2
	if head_history.size() > max_len:
		head_history.resize(max_len)
	for i in range(parts.size()):
		var idx_f: float = (i + 1) * spacing_frames
		var idx: int = int(idx_f)
		idx = min(idx, head_history.size() - 1)
		var part: Sprite2D = parts[i]
		var collider: CollisionShape2D = segment_colliders[i]
		var interp_pos: Vector2
		if idx + 1 < head_history.size():
			var fraction: float = idx_f - float(idx)
			interp_pos = head_history[idx].lerp(head_history[idx + 1], fraction)
		else:
			interp_pos = head_history[idx]
		var part_rot: float = (head_history[idx - 1] - head_history[idx]).angle()
		part.global_position = interp_pos
		part.global_rotation = part_rot
		collider.global_position = interp_pos
		collider.global_rotation = part_rot

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0 and not is_dying:
		_initiate_death()

func _initiate_death() -> void:
	health = 0
	is_dying = true
	area2D_Damage.set_deferred("monitoring", false)
	for collider in segment_colliders:
		collider.set_deferred("disabled", true)
	head_collider.set_deferred("disabled", true)
	visuals.z_index = 10
	hp_bar.queue_free()
	var head_dir: Vector2 = Vector2.ZERO
	var head_offset: Vector2 = head.global_position - global_position
	if head_offset.length() > 0.0:
		head_dir = head_offset.normalized()
	part_velocities.append(head_dir.rotated(randf_range(-PI, PI)) * randf_range(death_kick_min, death_kick_max))
	for part in parts:
		var dir: Vector2 = Vector2.ZERO
		var offset: Vector2 = part.global_position - global_position
		if offset.length() > 0.0:
			dir = offset.normalized()
		part_velocities.append(dir.rotated(randf_range(-PI, PI)) * randf_range(death_kick_min, death_kick_max))

func _on_DamageArea_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	head.play("bite_execute")
	skip_bite_exit = true
	was_hitting_player = true

	body.take_damage(65)
	var diff: Vector2 = body.global_position - global_position
	var knock_dir: Vector2 = Vector2.ZERO
	if diff.length() > 0.0:
		knock_dir = diff.normalized()
	var knockback_force: Vector2 = knock_dir * knockback_strength
	body.knockback(knockback_force)

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
