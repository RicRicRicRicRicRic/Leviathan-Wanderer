#scyphozoa_rex_projectile.gd
extends RigidBody2D

@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

@export var damage_amount: int = 125
@export var projectile_speed: float = 1500.0

var _direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_physics_process(true)
	set_process_mode(Node.PROCESS_MODE_PAUSABLE)
	set_as_top_level(false)
	add_to_group("enemy_proj")
	contact_monitor = true
	max_contacts_reported = 1

	body_entered.connect(_on_body_entered)


	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player_node = players[0]
		_direction = (player_node.global_position - global_position).normalized()
		rotation = _direction.angle() + deg_to_rad(90)  
		linear_velocity = _direction * projectile_speed

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
	queue_free()  

func set_damage_amount(amount: int) -> void:
	damage_amount = amount

func set_speed(speed: float) -> void:
	projectile_speed = speed
	linear_velocity = _direction * projectile_speed

func set_direction(direction_vec: Vector2) -> void:
	_direction = direction_vec.normalized()
	linear_velocity = _direction * projectile_speed
