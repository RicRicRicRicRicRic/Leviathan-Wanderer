#worm.gd
extends "res://scripts/Optimization/Interpolate.gd"

@export var max_health: int = 900
@export var scan_radius: float = 4000.0
@export var noturn_radius: float = 200.0
@export var move_speed: float = 900.0
@export var move_speed_noturn: float = 700.0
@export var max_turn_angle: float = 90.0
@export var decel_rate: float = 1000.0

@onready var visuals: Node2D        = $Node2D
@onready var head: AnimatedSprite2D = $Node2D/AnimatedSprite2D_head
@onready var body_main: Sprite2D    = head.get_node("Sprite2D_body1") as Sprite2D
@onready var body_1: Sprite2D       = body_main.get_node("Sprite2D_body1") as Sprite2D
@onready var body_2: Sprite2D       = body_1.get_node("Sprite2D_body2") as Sprite2D
@onready var body_3: Sprite2D       = body_2.get_node("Sprite2D_body3") as Sprite2D
@onready var body_4: Sprite2D       = body_3.get_node("Sprite2D_body4") as Sprite2D
@onready var body_5: Sprite2D       = body_4.get_node("Sprite2D_body5") as Sprite2D
@onready var body_6: Sprite2D       = body_5.get_node("Sprite2D_body6") as Sprite2D
@onready var body_7: Sprite2D       = body_6.get_node("Sprite2D_body7") as Sprite2D
@onready var tail: Sprite2D         = body_7.get_node("Sprite2D_tail") as Sprite2D

var current_speed: float = 0.0
var is_dying: bool = false
var health: int

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position
	health = max_health
	current_speed = move_speed
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	previous_position = global_position
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null:
		return
	var to_player: Vector2 = player_node.global_position - global_position
	var dist: float = to_player.length()
	if dist > scan_radius:
		return
	if dist <= noturn_radius:
		if current_speed > move_speed_noturn:
			current_speed -= decel_rate * delta
			if current_speed < move_speed_noturn:
				current_speed = move_speed_noturn
		var forward_noturn: Vector2 = Vector2.RIGHT.rotated(rotation)
		position += forward_noturn * current_speed * delta
		return
	if current_speed < move_speed:
		current_speed += decel_rate * delta
		if current_speed > move_speed:
			current_speed = move_speed
	var target_angle: float = to_player.angle()
	var angle_diff: float = wrapf(target_angle - rotation, -PI, PI)
	var max_step: float = deg_to_rad(max_turn_angle) * delta
	if angle_diff > max_step:
		rotation += max_step
	elif angle_diff < -max_step:
		rotation -= max_step
	else:
		rotation += angle_diff
	var forward: Vector2 = Vector2.RIGHT.rotated(rotation)
	position += forward * current_speed * delta
	

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0 and not is_dying:
		health = 0
		is_dying = true
		scan_radius = 0
		current_speed = 0
		$CollisionShape2D.set_deferred("disabled", true)

func heal(amount: int) -> void:
	health += amount
	if health > max_health:
		health = max_health
