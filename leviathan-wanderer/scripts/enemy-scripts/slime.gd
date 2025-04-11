#slime.gd
extends "res://scripts/Optimization/Interpolate.gd"

const SPEED: float = 280.0
const GRAVITY: float = 980.0

@onready var visuals: Node2D = $Node2D
@onready var slime_main: AnimatedSprite2D = visuals.get_node("AnimatedSprite2D") as AnimatedSprite2D
@onready var raycast_wall: RayCast2D = visuals.get_node("RayCast2D_wall") as RayCast2D
@onready var raycast_fall: RayCast2D = visuals.get_node("RayCast2D_height") as RayCast2D
@onready var head_collision: CollisionShape2D = $CollisionShape2D_head
@onready var body_collision: CollisionShape2D = $CollisionShape2D_body
@onready var damage_area: Area2D = $DamageArea
@onready var Time_before_turn: Timer = $Timer

var head_original_x: float
var head_original_rot_deg: float
var body_original_x: float

var direction: int = -1
var was_colliding: bool = false
var should_flip: bool = false

var health: int = 350

func _ready() -> void:
	add_to_group("enemy")
	interp_visuals = visuals
	previous_position = global_position
	raycast_wall.collision_mask = (1 << 1) | (1 << 2)
	raycast_wall.enabled = true
	raycast_fall.enabled = true

	head_original_x = head_collision.position.x
	head_original_rot_deg = rad_to_deg(head_collision.rotation)
	body_original_x = body_collision.position.x

	damage_area.body_entered.connect(_on_DamageArea_body_entered)
	Time_before_turn.timeout.connect(_on_Timer_timeout)

func update_collision_shapes() -> void:
	if direction == 1:
		head_collision.position.x = -head_original_x
		head_collision.rotation = deg_to_rad(180.0 - head_original_rot_deg)
		body_collision.position.x = -body_original_x
	else:
		head_collision.position.x = head_original_x
		head_collision.rotation = deg_to_rad(head_original_rot_deg)
		body_collision.position.x = body_original_x

func _physics_process(delta: float) -> void:
	previous_position = global_position

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	var is_colliding: bool = raycast_wall.is_colliding()

	if is_colliding and not was_colliding and Time_before_turn.is_stopped():
		Time_before_turn.start()
		should_flip = true
		velocity.x = 0.0 
	elif not is_colliding:
		Time_before_turn.stop()
		should_flip = false

	if Time_before_turn.is_stopped():
		velocity.x = SPEED * direction
		visuals.scale.x = 1.0 if direction == -1 else -1.0

	was_colliding = is_colliding

	move_and_slide()
	update_collision_shapes()

func _on_Timer_timeout() -> void:
	if should_flip:
		direction *= -1
		should_flip = false

func _on_DamageArea_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(65)

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	if health <= 0:
		queue_free()
