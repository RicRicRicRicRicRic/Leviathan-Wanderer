# isopod.gd
extends "res://scripts/Utility/Interpolate.gd"

@export var max_health: int = 700
@export var detect_player_scan_radius: float = 2000.0
@export var transform_to_curl_scan_radius: float = 850.0
@export var curled_form: PackedScene = preload("res://scene/enemyscene/isopod/isopod_curled.tscn")
@export var speed: float = 425.0
@export var knockback_strength: int = 1000
@export var avoidance_turn_speed: float = 5.0
@export var rotation_speed: float = 10.0


@onready var visuals: Node2D = $Node2D
@onready var isopod_anim: AnimatedSprite2D = $Node2D/AnimatedSprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var second_collider: CollisionShape2D = $CollisionShape2D2
@onready var damage_area: Area2D = $Area2D
@onready var timer_curlcooldown: Timer = $Timer_curlcooldown
@onready var detect_obstacle: RayCast2D = $RayCast2D_Forward
@onready var raycast_nodes: Node2D = $Node2D_raycasts
@onready var detect_left: RayCast2D = $Node2D_raycasts/RayCast2D_Left
@onready var detect_right: RayCast2D = $Node2D_raycasts/RayCast2D_Right

var health: int
var is_dying: bool = false
var is_curling: bool = false
var is_avoiding_obstacle: bool = false
var last_player_position: Vector2
var last_direction: Vector2
var player: Node2D
var can_curl: bool = true
var curled_instance: Node2D = null
var _current_avoidance_turn_sign: float = 0.0 

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position
	health = max_health
	add_to_group("enemy")
	player = get_tree().get_nodes_in_group("player")[0] as Node2D
	damage_area.body_entered.connect(_on_DamageArea_body_entered)
	timer_curlcooldown.timeout.connect(_on_Timer_curlcooldown_timeout)
	isopod_anim.animation_finished.connect(_on_animation_finished)
	detect_obstacle.add_exception(player)
	detect_left.add_exception(player)
	detect_right.add_exception(player)
	for curled in get_tree().get_nodes_in_group("isopod_curled"):
		detect_obstacle.add_exception(curled)
		detect_left.add_exception(curled)
		detect_right.add_exception(curled)

func _physics_process(_delta: float) -> void:
	if is_curling and curled_instance:
		global_position = curled_instance.global_position
		return
	previous_position = global_position
	if is_dying:
		return

	var dir_to_player: Vector2 = (player.global_position - global_position).normalized()
	var dist_to_player: float = global_position.distance_to(player.global_position)
	detect_obstacle.target_position = (player.global_position - global_position)

	var hit_fwd: bool = detect_obstacle.is_colliding() and detect_obstacle.get_collider() != player
	var hit_left: bool = detect_left.is_colliding() and detect_left.get_collider() != player
	var hit_right: bool = detect_right.is_colliding() and detect_right.get_collider() != player
	var obstacle_detected: bool = hit_fwd or hit_left or hit_right

	if obstacle_detected:
		if not is_avoiding_obstacle:
			is_avoiding_obstacle = true
			last_direction = dir_to_player
	else:
		is_avoiding_obstacle = false
		_current_avoidance_turn_sign = 0.0

	if is_curling:
		return

	var target_dir: Vector2 = dir_to_player

	if is_avoiding_obstacle:
		var avoid_dir_decision: Vector2

		if hit_left and not hit_right:
			avoid_dir_decision = last_direction.rotated(deg_to_rad(avoidance_turn_speed))
			_current_avoidance_turn_sign = 1.0
		elif hit_right and not hit_left:
			avoid_dir_decision = last_direction.rotated(deg_to_rad(-avoidance_turn_speed))
			_current_avoidance_turn_sign = -1.0
		elif hit_left and hit_right:
			if _current_avoidance_turn_sign == 0.0:
				if last_direction.cross(dir_to_player) > 0:
					_current_avoidance_turn_sign = -1.0
				else:
					_current_avoidance_turn_sign = 1.0
			avoid_dir_decision = last_direction.rotated(deg_to_rad(avoidance_turn_speed * _current_avoidance_turn_sign))
		elif hit_fwd:
			if _current_avoidance_turn_sign == 0.0:
				_current_avoidance_turn_sign = 1.0
			avoid_dir_decision = last_direction.rotated(deg_to_rad(avoidance_turn_speed * _current_avoidance_turn_sign))
		else:
			if _current_avoidance_turn_sign != 0.0:
				avoid_dir_decision = last_direction.rotated(deg_to_rad(avoidance_turn_speed * _current_avoidance_turn_sign))
			else:
				avoid_dir_decision = last_direction

		last_direction = last_direction.lerp(avoid_dir_decision.normalized(), _delta * 10.0)
		target_dir = last_direction.normalized()
	else:
		last_direction = dir_to_player

	var tgt_angle: float = target_dir.angle() + PI / 2
	visuals.rotation = lerp_angle(visuals.rotation, tgt_angle, _delta * rotation_speed)
	collider.rotation = visuals.rotation
	damage_area.rotation = visuals.rotation
	raycast_nodes.rotation = visuals.rotation

	if dist_to_player <= detect_player_scan_radius:
		velocity = target_dir * speed
	else:
		velocity = Vector2.ZERO
		is_avoiding_obstacle = false
		_current_avoidance_turn_sign = 0.0

	if velocity.length() > 0:
		isopod_anim.play("crawl")
	else:
		isopod_anim.play("iddle")

	move_and_slide()

	if dist_to_player <= transform_to_curl_scan_radius and can_curl and not is_curling:
		var forward_obstacle_is_player = detect_obstacle.is_colliding() and detect_obstacle.get_collider() == player
		if not hit_fwd or forward_obstacle_is_player:
			is_curling = true
			velocity = Vector2.ZERO
			isopod_anim.play("curl")


func _on_DamageArea_body_entered(body: Node) -> void:
	if is_curling:
		return
	if not body.is_in_group("player"):
		return
	body.take_damage(25)
	var diff: Vector2 = body.global_position - global_position
	var knock_dir: Vector2 = Vector2.ZERO
	if diff.length() > 0.0:
		knock_dir = diff.normalized()
	var knockback_force: Vector2 = knock_dir * knockback_strength
	body.knockback(knockback_force)

func take_damage(amount: int) -> void:
	if is_curling:
		return
	health -= amount
	if health <= 0 and not is_dying:
		health = 0
		velocity = Vector2.ZERO
		is_dying = true
		collider.set_deferred("disabled", true)
		second_collider.set_deferred("disabled", true)
		damage_area.set_deferred("monitoring", false)
		isopod_anim.play("death")

func _on_animation_finished() -> void:
	if is_dying and isopod_anim.animation == "death":
		queue_free()
	elif is_curling and isopod_anim.animation == "curl":
		visuals.visible = false
		collider.disabled = true
		damage_area.monitoring = false
		curled_instance = curled_form.instantiate() as Node2D
		var parent_node = get_parent()
		if parent_node != null:
			parent_node.add_child(curled_instance)
			curled_instance.position = position
		detect_obstacle.add_exception(curled_instance)
		detect_left.add_exception(curled_instance)
		detect_right.add_exception(curled_instance)
		if is_instance_valid(curled_instance) and curled_instance.has_node("AnimatedSprite2D"):
			curled_instance.get_node("AnimatedSprite2D").animation_finished.connect(Callable(self, "_on_curled_animation_finished").bind(curled_instance))
		health = min(health + 150, max_health)

func heal(amount: int) -> void:
	health = min(health + amount, max_health)

func _on_Timer_curlcooldown_timeout() -> void:
	can_curl = true

func _on_curled_animation_finished(curled_node: Node) -> void:
	if curled_node and is_instance_valid(curled_node) and curled_node.is_uncurling and is_instance_valid(curled_node.get_node("AnimatedSprite2D")) and curled_node.get_node("AnimatedSprite2D").animation == "uncurl":
		global_position = curled_node.global_position
		detect_obstacle.remove_exception(curled_node)
		detect_left.remove_exception(curled_node)
		detect_right.remove_exception(curled_node)
		curled_node.queue_free()
		curled_instance = null
		visuals.visible = true
		collider.disabled = false
		damage_area.monitoring = true
		is_curling = false
		can_curl = false
		timer_curlcooldown.start()
		initialize_after_uncurl()

func initialize_after_uncurl() -> void:
	can_curl = false
	timer_curlcooldown.start()
	is_avoiding_obstacle = false
	last_direction = Vector2.ZERO
