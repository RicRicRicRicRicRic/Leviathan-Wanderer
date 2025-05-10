#slug.gd
extends "res://scripts/Optimization/Interpolate.gd"

const SPEED: float = 380.0
const GRAVITY: float = 980.0

@export var max_health: int = 475
@export var knockback_strength: float = 1200.0

var health: int = max_health

@onready var visuals: Node2D = $Node2D
@onready var slime_main: AnimatedSprite2D = visuals.get_node("AnimatedSprite2D") as AnimatedSprite2D
@onready var raycast_wall: RayCast2D = visuals.get_node("RayCast2D_wall") as RayCast2D
@onready var raycast_fall: RayCast2D = visuals.get_node("RayCast2D_height") as RayCast2D
@onready var damage_area: Area2D = visuals.get_node("DamageArea") as Area2D
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D_collider as CollisionPolygon2D
@onready var turn_timer: Timer = $Timer as Timer
@export var projectile_scene: PackedScene = preload("res://scene/enemyscene/slug/slug_healing_orbs.tscn")

var orb_spawned: bool = false
var collision_original_x: float = 0.0
var direction: int = -1
var was_colliding: bool = false
@export var should_flip: bool = false
var is_dying: bool = false

func _ready() -> void:
	randomize()
	interp_visuals = visuals
	previous_position = global_position
	add_to_group("enemy")
	raycast_wall.enabled = true
	raycast_fall.enabled = true
	raycast_wall.add_exception(self)
	raycast_fall.add_exception(self)
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node:
		raycast_wall.add_exception(player_node)
		raycast_fall.add_exception(player_node)
	collision_original_x = collision_shape.position.x
	damage_area.body_entered.connect(_on_DamageArea_body_entered)
	turn_timer.timeout.connect(_on_Timer_timeout)
	slime_main.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if is_dying:
		return
	previous_position = global_position
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	raycast_fall.force_raycast_update()
	raycast_wall.force_raycast_update()
	var wall_hit: bool = raycast_wall.is_colliding()
	var drop: bool = not raycast_fall.is_colliding()
	var should_turn_now: bool = wall_hit or drop
	if should_turn_now and not was_colliding and turn_timer.is_stopped():
		turn_timer.start()
		should_flip = true
		velocity.x = 0.0
		slime_main.play("iddle")
	elif not should_turn_now:
		turn_timer.stop()
		should_flip = false
	if turn_timer.is_stopped():
		velocity.x = SPEED * direction
		if direction == -1:
			visuals.scale.x = 1.0
			collision_shape.scale.x = 1.0
			collision_shape.position.x = collision_original_x
		else:
			visuals.scale.x = -1.0
			collision_shape.scale.x = -1.0
			collision_shape.position.x = -collision_original_x
		if slime_main.animation != "walk" or not slime_main.is_playing():
			slime_main.play("walk")
	was_colliding = should_turn_now
	move_and_slide()

func _on_Timer_timeout() -> void:
	if should_flip:
		direction *= -1
		should_flip = false

func _on_DamageArea_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var diff: Vector2 = body.global_position - global_position
		var knock_dir: Vector2
		if diff.length() > 0:
			knock_dir = diff.normalized()
		else:
			knock_dir = Vector2(-direction, 0)
		var knockback_force: Vector2 = knock_dir * knockback_strength
		body.take_damage(65)
		body.knockback(knockback_force)

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	if health <= 0 and not orb_spawned and not is_dying:
		is_dying = true
		orb_spawned = true
		velocity = Vector2.ZERO
		collision_shape.set_deferred("disabled", true)
		damage_area.set_deferred("monitoring", false)
		slime_main.play("death")

func _on_animation_finished() -> void:
	if is_dying and slime_main.animation == "death":
		call_deferred("spawn_healing_orbs")
		queue_free()

func heal(amount: float) -> void:
	health = min(health + amount, max_health)

func spawn_healing_orbs() -> void:
	var count: int = randi_range(5, 8)
	for i in int(count):
		var orb: RigidBody2D = projectile_scene.instantiate() as RigidBody2D
		get_parent().add_child(orb)
		orb.global_position = Vector2(global_position.x, global_position.y + 65.0)
		orb.add_to_group("healing_orb")
