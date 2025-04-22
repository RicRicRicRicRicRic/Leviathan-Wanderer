#electric_orbs.g
extends RigidBody2D
class_name ElectricOrb

static var SPEED: float = 1200.0
static var BURST_SIZE: int = 3

@export var damage: int = 35

@onready var delete_timer: Timer = $Timer_despawn
@onready var timer_fire_rate: Timer = $Timer_fire_rate
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	delete_timer.timeout.connect(_on_delete_timer_timeout)
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(Callable(self, "_on_body_entered"))

static func shoot(start_pos: Vector2, target_pos: Vector2, orb_scene: PackedScene) -> void:
	var scene = Engine.get_main_loop().current_scene

	for i in range(BURST_SIZE):
		var orb: ElectricOrb = orb_scene.instantiate() as ElectricOrb
		orb.global_position = start_pos

		var angle: float = (target_pos - start_pos).angle()
		orb.rotation = angle
		orb.linear_velocity = Vector2(SPEED, 0).rotated(angle)

		scene.add_child(orb)

		orb.timer_fire_rate.start()
		await orb.timer_fire_rate.timeout

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
