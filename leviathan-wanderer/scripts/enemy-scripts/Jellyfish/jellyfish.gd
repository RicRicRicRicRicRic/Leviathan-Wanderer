# jellyfish.gd
extends "res://scripts/Optimization/Interpolate.gd"

@export var max_health: int = 600
@export var long_scan_radius: float = 2500.0
@export var medium_scan_radius: float = 750.0
@export var short_scan_radius: float = 500.0
@export var move_speed: float = 450.0
@export var hover_speed: float = 25.0
@export var electric_orb_scene: PackedScene = preload("res://scene/enemyscene/jellyfish/electric_orbs.tscn")

var mobility_time: float
var hover_time: float
var health: int
var is_dying: bool = false
var hover_direction: int = 1

@onready var visuals: Node2D = $Node2D
@onready var jellyfish_main: AnimatedSprite2D = visuals.get_node("AnimatedSprite2D") as AnimatedSprite2D
@onready var timer_shoot_interval: Timer = $Timer_shoot_interval
@onready var timer_mobility: Timer = $Timer_mobility
@onready var timer_hover: Timer = $Timer_hover
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var detect_floor: RayCast2D = $RayCast2D
@onready var marker: Marker2D = visuals.get_node("Marker2D") as Marker2D

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position
	health = max_health
	add_to_group("enemy")
	jellyfish_main.animation_finished.connect(_on_animation_finished)

	mobility_time = timer_mobility.wait_time
	hover_time = timer_hover.wait_time
	timer_hover.connect("timeout", Callable(self, "_on_mobility_timeout"))
	timer_hover.start()

	timer_shoot_interval.connect("timeout", Callable(self, "_on_shoot_interval_timeout"))
	

func _physics_process(delta: float) -> void:
	previous_position = global_position
	if is_dying:
		return

	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var target_vel: Vector2 = Vector2.ZERO

	if player_node != null:
		var dir_vec: Vector2 = (player_node.global_position - global_position).normalized()
		var dist: float = player_node.global_position.distance_to(global_position)

		if dist <= long_scan_radius and dist > medium_scan_radius:
			target_vel = dir_vec * move_speed
		elif dist <= medium_scan_radius and dist > short_scan_radius:
			target_vel = Vector2.ZERO
		elif dist <= short_scan_radius:
			target_vel = -dir_vec * move_speed

		if detect_floor.is_colliding():
			target_vel.y = -move_speed

		if dist <= long_scan_radius:
			if timer_shoot_interval.is_stopped():
				timer_shoot_interval.start()
		else:
			if not timer_shoot_interval.is_stopped():
				timer_shoot_interval.stop()

	target_vel.y += hover_direction * hover_speed
	var accel: float = move_speed / mobility_time
	velocity = velocity.move_toward(target_vel, accel * delta)
	move_and_slide()

func _on_mobility_timeout() -> void:
	hover_direction = -hover_direction
	timer_hover.start()

func _on_shoot_interval_timeout() -> void:
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node != null:
		ElectricOrb.shoot(marker.global_position, player_node.global_position, electric_orb_scene)
		

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0 and not is_dying:
		health = 0
		is_dying = true
		velocity = Vector2.ZERO
		collision_shape.set_deferred("disabled", true)
		jellyfish_main.play("death")

func _on_animation_finished() -> void:
	if is_dying and jellyfish_main.animation == "death":
		queue_free()

func heal(amount: int) -> void:
	health += amount
	if health > max_health:
		health = max_health
