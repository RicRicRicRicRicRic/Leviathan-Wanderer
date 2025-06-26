# shield.gd
extends StaticBody2D

signal shield_broken

@onready var player_node: Node2D = null
@onready var colider: CollisionPolygon2D = $CollisionPolygon2D

@export var rotation_speed: float = 1.0
@export var max_health: float = 3500.0
var current_health: float

func _ready() -> void:
	current_health = max_health
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_node = players[0]
	
	add_to_group("enemy_shield")

func _physics_process(delta: float) -> void:
	if player_node:
		var direction_to_player = (player_node.global_position - global_position).normalized()
		var target_angle = direction_to_player.angle() + PI / 2.0
		rotation = lerp_angle(rotation, target_angle, delta * rotation_speed)

func take_damage(amount: float) -> void:
	current_health -= amount
	
	if current_health <= 0:
		shield_broken.emit() 
		queue_free()
