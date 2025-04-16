#slug.gd
extends "res://scripts/Optimization/Interpolate.gd"

const SPEED: float = 380.0           
const GRAVITY: float = 980.0         

@export var max_health: int = 475
var health: int = max_health

@onready var visuals: Node2D = $Node2D
@onready var slime_main: AnimatedSprite2D = visuals.get_node("AnimatedSprite2D") as AnimatedSprite2D
@onready var raycast_wall: RayCast2D = visuals.get_node("RayCast2D_wall") as RayCast2D
@onready var raycast_fall: RayCast2D = visuals.get_node("RayCast2D_height") as RayCast2D
@onready var damage_area: Area2D = visuals.get_node("DamageArea") as Area2D
@onready var head_collision: CollisionShape2D = $CollisionShape2D_head
@onready var body_collision: CollisionShape2D = $CollisionShape2D_body
@onready var Time_before_turn: Timer = $Timer

var head_original_x: float
var head_original_rot_deg: float
var body_original_x: float
var direction: int = -1
var was_colliding: bool = false
var should_flip: bool = false
var player_in_contact: Node = null

func _ready() -> void:
	add_to_group("enemy")
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		raycast_wall.add_exception(player_node)
	interp_visuals = visuals
	previous_position = global_position
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
		head_collision.rotation = 0.0  
		body_collision.position.x = -body_original_x
	else:
		head_collision.position.x = head_original_x
		head_collision.rotation = 0.0
		body_collision.position.x = body_original_x

func _physics_process(delta: float) -> void:
	previous_position = global_position
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	raycast_fall.force_raycast_update()
	raycast_wall.force_raycast_update()
	var wall_detected: bool = raycast_wall.is_colliding()
	var fall_detected: bool = not raycast_fall.is_colliding()
	var should_turn: bool = (wall_detected or fall_detected)

	if should_turn and not was_colliding and Time_before_turn.is_stopped():
		Time_before_turn.start()
		should_flip = true
		velocity.x = 0.0  
		slime_main.play("iddle")
	elif not should_turn:
		Time_before_turn.stop()
		should_flip = false

	if Time_before_turn.is_stopped():
		velocity.x = SPEED * direction
		visuals.scale.x = 1.0 if direction == -1 else -1.0
		if not slime_main.is_playing() or slime_main.animation != "walk":
			slime_main.play("walk")
	was_colliding = should_turn
	move_and_slide()
	update_collision_shapes()

func _on_Timer_timeout() -> void:
	if should_flip:
		direction *= -1
		should_flip = false

func _on_DamageArea_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var knock_dir: Vector2 = Vector2.ZERO
		var diff: Vector2 = body.global_position - global_position
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
