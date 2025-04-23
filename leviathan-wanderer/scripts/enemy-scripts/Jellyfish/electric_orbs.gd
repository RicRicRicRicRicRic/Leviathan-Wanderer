#electric_orbs.g
extends RigidBody2D
class_name ElectricOrb

static var SPEED: float = 1200.0
static var BURST_SIZE: int = 3

@export var damage: int = 35

@onready var delete_timer: Timer = $Timer_despawn
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	delete_timer.timeout.connect(_on_delete_timer_timeout)
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
	sprite.queue_free()
	collider.queue_free()
	$GPUParticles2D.emitting = false
	if not $GPUParticles2D.emitting:
		delete_timer.start()

func _on_delete_timer_timeout() -> void:
	queue_free()
