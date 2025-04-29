#worm.gd
extends "res://scripts/Optimization/Interpolate.gd"

@export var max_heatlh: int = 900
@export var scan_radius: float = 4000.0
@export var move_speed: float = 600.0

@onready var visuals: Node2D = $Node2D
@onready var head: AnimatedSprite2D = $Node2D/AnimatedSprite2D_head
@onready var head_collider: CollisionShape2D = $CollisionShape2D_head
@onready var timer_HitDelay: Timer = $Timer_HitDelay

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position

func _physics_process(delta: float) -> void:
	previous_position = global_position
	var player_node := get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null:
		return
	var to_player : Vector2 = player_node.global_position - global_position
	var dist := to_player.length()
	if dist > scan_radius:
		return
	var desired_angle := to_player.angle()
	var max_turn := deg_to_rad(45)
	var delta_ang := wrapf(desired_angle - rotation, -PI, PI)
	delta_ang = clamp(delta_ang, -max_turn, max_turn)
	rotation += delta_ang
	visuals.rotation = rotation
	global_position += Vector2.RIGHT.rotated(rotation) * move_speed * delta

func on_timer_HitDelay_timeout() -> void:
	pass
