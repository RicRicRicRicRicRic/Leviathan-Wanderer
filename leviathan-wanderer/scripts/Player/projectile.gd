# projectile.gd
extends RigidBody2D
class_name Projectile

static var SPEED: float = 1400.0
static var FIRE_RATE: float = 0.125

var dir: float = 0.0
var spawnPos: Vector2 = Vector2.ZERO
var spawnRot: float = 0.0
var hit_count: int = 0
@export var max_hits: int = 10
@export var damage: float = 42

@onready var delete_timer: Timer = $Timer
@onready var anisprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D

static func shoot(start_pos: Vector2, target: Vector2, projectile_scene: PackedScene, shooter: Node) -> void:
	var time_now: float = Time.get_ticks_msec() / 1000.0
	var last_shot_time: float = shooter.get_meta("last_shot_time", -Projectile.FIRE_RATE) as float
	if time_now - last_shot_time < Projectile.FIRE_RATE:
		return
	shooter.set_meta("last_shot_time", time_now)

	var proj: Projectile = projectile_scene.instantiate() as Projectile
	var angle: float = (target - start_pos).angle()
	proj.spawnPos = start_pos
	proj.dir = angle
	proj.spawnRot = angle
	proj.rotation = angle

	if target.x < start_pos.x and proj.has_node("AnimatedSprite2D"):
		var sprite: AnimatedSprite2D = proj.get_node("AnimatedSprite2D") as AnimatedSprite2D
		sprite.flip_v = true

	proj.add_collision_exception_with(shooter)
	var scene: Node = shooter.get_tree().current_scene
	scene.add_child(proj)

func _ready() -> void:
	delete_timer.timeout.connect(_on_delete_timer_timeout)
	global_position = spawnPos
	global_rotation = spawnRot
	add_to_group("projectiles")
	contact_monitor = true
	max_contacts_reported = max_hits
	body_entered.connect(_on_body_entered)
	for p_item in get_tree().get_nodes_in_group("projectiles"):
		if p_item != self:
			add_collision_exception_with(p_item)
	linear_velocity = Vector2(SPEED, 0).rotated(dir)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
	anisprite.queue_free()
	collider.queue_free()
	$GPUParticles2D.emitting = false
	if not $GPUParticles2D.emitting:
		delete_timer.start()

func _on_delete_timer_timeout() -> void:
	queue_free()
