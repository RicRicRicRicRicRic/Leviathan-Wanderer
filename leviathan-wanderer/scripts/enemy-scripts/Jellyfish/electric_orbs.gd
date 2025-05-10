#electric_orbs.g
extends RigidBody2D
class_name ElectricOrb

static var SPEED: float = 1200.0

@export var damage: int = 35

@onready var delete_timer: Timer = $Timer_despawn
@onready var slow_timer: Timer = $Timer_slow
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var _player_node: Node = null 

func _ready() -> void:
	delete_timer.timeout.connect(_on_delete_timer_timeout)
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)
	slow_timer.timeout.connect(_on_slow_timer_timeout)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		_player_node = body 
		body.take_damage(damage)
		body.apply_slow(0.35)
		body.apply_weakend_jump(0.6)  
		slow_timer.start()
	sprite.queue_free()
	collider.queue_free()
	$GPUParticles2D.emitting = false
	if not $GPUParticles2D.emitting:
		delete_timer.start()

func _on_delete_timer_timeout() -> void:
	queue_free()

func _on_slow_timer_timeout() -> void:
	if _player_node != null and _player_node.has_method("reset_speed"):
		_player_node.reset_speed()
	if _player_node != null and _player_node.has_method("reset_jump"):
		_player_node.reset_jump()
	_player_node = null 
