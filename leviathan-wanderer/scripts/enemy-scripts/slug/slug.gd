#slug.gd
extends "res://scripts/Optimization/Interpolate.gd"

const SPEED: float = 380.0
const GRAVITY: float = 980.0

@export var max_health: int = 475
var health: int = max_health

@onready var visuals         := $Node2D
@onready var trail_area      := visuals.get_node("TrailArea")          as Node
@onready var slime_main      := visuals.get_node("AnimatedSprite2D")    as AnimatedSprite2D
@onready var raycast_wall    := visuals.get_node("RayCast2D_wall")     as RayCast2D
@onready var raycast_fall    := visuals.get_node("RayCast2D_height")   as RayCast2D
@onready var damage_area     := visuals.get_node("DamageArea")         as Area2D
@onready var collision_shape := $CollisionPolygon2D_collider             as CollisionPolygon2D
@onready var turn_timer      := $Timer                                 as Timer

var collision_original_x: float
var direction: int       = -1
var was_colliding: bool  = false
var should_flip: bool    = false

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position
	add_to_group("enemy")

	raycast_wall.enabled = true
	raycast_fall.enabled = true
	raycast_wall.add_exception(self)
	raycast_fall.add_exception(self)
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		raycast_wall.add_exception(player_node)
		raycast_fall.add_exception(player_node)

	collision_original_x = collision_shape.position.x
	damage_area.body_entered.connect(_on_DamageArea_body_entered)
	turn_timer.timeout.connect(_on_Timer_timeout)

func _physics_process(delta: float) -> void:
	previous_position = global_position
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	raycast_fall.force_raycast_update()
	raycast_wall.force_raycast_update()

	var wall_hit = raycast_wall.is_colliding()
	var drop     = not raycast_fall.is_colliding()
	var should_turn_now = wall_hit or drop

	if should_turn_now and not was_colliding and turn_timer.is_stopped():
		turn_timer.start()
		should_flip = true
		velocity.x = 0
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
		trail_area.call("reset_polygons")

func _on_DamageArea_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var diff = body.global_position - global_position
		var knock_dir: Vector2
		if diff.length() > 0:
			knock_dir = diff.normalized()
		else:
			knock_dir = Vector2(-direction, 0)
		body.knockback(knock_dir)
		body.take_damage(65)

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	if health <= 0:
		queue_free()
