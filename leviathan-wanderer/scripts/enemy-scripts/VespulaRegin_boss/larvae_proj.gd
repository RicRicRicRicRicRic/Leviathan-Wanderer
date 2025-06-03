# larvae_proj.gd
extends RigidBody2D
class_name Larvae_proj

var current_speed: float = 600.0 
const MAX_SPEED: float = 950.0   
const ACCELERATION_RATE: float = 150.0
const MAX_HOMING_TURN_RATE_DEG: float = 90

@export var damage: int = 4

@onready var delete_timer: Timer = $Timer_despawn
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var _player_node: Node = null
var _is_homing_active: bool = false

func _ready() -> void:
	delete_timer.timeout.connect(_on_delete_timer_timeout)
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	current_speed = min(current_speed + ACCELERATION_RATE * delta, MAX_SPEED)

	if _is_homing_active and _player_node and is_instance_valid(_player_node):
		var target_direction = (_player_node.global_position - global_position).normalized()
		var target_angle = target_direction.angle()
		var current_angle = rotation
		var angle_diff = wrapf(target_angle - current_angle, -PI, PI)
		var max_rotation_rad = deg_to_rad(MAX_HOMING_TURN_RATE_DEG) * delta
		var clamped_angle_diff = clamp(angle_diff, -max_rotation_rad, max_rotation_rad)
		rotation += clamped_angle_diff
	
	linear_velocity = Vector2.RIGHT.rotated(rotation) * current_speed 


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		_player_node = body
		body.take_damage(damage)
	sprite.queue_free()
	collider.queue_free()
	$GPUParticles2D.emitting = false
	current_speed = 0
	if not $GPUParticles2D.emitting:
		delete_timer.start()

func _on_delete_timer_timeout() -> void:
	queue_free()
