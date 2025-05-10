# isopod.gd
extends "res://scripts/Optimization/Interpolate.gd"

@export var max_health: int = 750
@export var detect_player_scan_radius: float = 2000.0
@export var transform_to_curl_scan_radius: float = 700.0
@export var curled_form: PackedScene = preload("res://scene/enemyscene/isopod/isopod_curled.tscn")
@export var speed: float = 425.0
@export var knockback_strength: float = 1000

@onready var visuals: Node2D = $Node2D
@onready var isopod_anim: AnimatedSprite2D = $Node2D/AnimatedSprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $Area2D
@onready var timer_curlcooldown: Timer = $Timer_curlcooldown
@onready var detect_obstacle: RayCast2D = $RayCast2D_obstacle

var health: int
var is_dying: bool = false
var is_curling: bool = false
var is_avoiding_obstacle: bool = false
var last_player_position: Vector2
var last_direction: Vector2
var player: Node2D
var can_curl: bool = true
var curled_instance: Node = null

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position
	health = max_health
	add_to_group("enemy")
	player = get_tree().get_nodes_in_group("player")[0]
	damage_area.body_entered.connect(_on_DamageArea_body_entered)
	timer_curlcooldown.timeout.connect(_on_Timer_curlcooldown_timeout)
	isopod_anim.animation_finished.connect(_on_animation_finished)
	detect_obstacle.add_exception(player)
	# Add existing curled isopods as exceptions
	for curled in get_tree().get_nodes_in_group("isopod_curled"):
		detect_obstacle.add_exception(curled)

func _physics_process(_delta: float) -> void:
	previous_position = global_position
	if is_dying:
		return

	var direction_to_player: Vector2 = (player.global_position - global_position).normalized()
	var distance_to_player: float = global_position.distance_to(player.global_position)

	# Update RayCast2D even when curled
	detect_obstacle.target_position = (player.global_position - global_position)
	if detect_obstacle.is_colliding() and detect_obstacle.get_collider() != player:
		if not is_avoiding_obstacle:
			is_avoiding_obstacle = true
			last_player_position = player.global_position
			last_direction = (last_player_position - global_position).normalized()
	else:
		is_avoiding_obstacle = false
		last_player_position = Vector2.ZERO

	if is_curling:
		if curled_instance:
			global_position = curled_instance.global_position
		return

	if distance_to_player <= detect_player_scan_radius:
		var target_direction: Vector2 = last_direction if is_avoiding_obstacle else direction_to_player
		var angle_to_target: float = target_direction.angle()
		visuals.rotation = angle_to_target + PI / 2
		collider.rotation = visuals.rotation
		damage_area.rotation = visuals.rotation

		if detect_obstacle.is_colliding() and detect_obstacle.get_collider() != player:
			velocity = last_direction * speed
		else:
			velocity = direction_to_player * speed
	else:
		velocity = Vector2.ZERO
		detect_obstacle.target_position = Vector2.ZERO
		is_avoiding_obstacle = false

	if velocity.length() > 0:
		isopod_anim.play("crawl")
	else:
		isopod_anim.play("iddle")

	move_and_slide()

	if distance_to_player <= transform_to_curl_scan_radius and can_curl and not is_curling:
		if not detect_obstacle.is_colliding() or detect_obstacle.get_collider() == player:
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
		damage_area.set_deferred("monitoring", false)
		isopod_anim.play("death")

func _on_animation_finished() -> void:
	if is_dying and isopod_anim.animation == "death":
		queue_free()
	elif is_curling and isopod_anim.animation == "curl":
		visuals.visible = false
		collider.disabled = true
		damage_area.monitoring = false
		var curled = curled_form.instantiate()
		curled.global_position = global_position
		curled_instance = curled
		get_parent().add_child(curled)
		detect_obstacle.add_exception(curled)
		curled.isopod_anim.animation_finished.connect(_on_curled_animation_finished)
		health += 200
		if health > max_health:
			health = max_health

func heal(amount: int) -> void:
	health += amount
	if health > max_health:
		health = max_health

func _on_Timer_curlcooldown_timeout() -> void:
	can_curl = true

func _on_curled_animation_finished() -> void:
	if curled_instance and curled_instance.is_uncurling and curled_instance.isopod_anim.animation == "uncurl":
		global_position = curled_instance.global_position
		curled_instance.queue_free()
		curled_instance = null
		visuals.visible = true
		collider.disabled = false
		damage_area.monitoring = true
		is_curling = false
		can_curl = false
		timer_curlcooldown.start()
		initialize_after_uncurl(last_player_position, is_avoiding_obstacle)

func initialize_after_uncurl(last_pos: Vector2 = Vector2.ZERO, avoiding: bool = false) -> void:
	can_curl = false
	timer_curlcooldown.start()
	if last_pos != Vector2.ZERO:
		last_player_position = last_pos
		is_avoiding_obstacle = avoiding
		last_direction = (last_player_position - global_position).normalized()
