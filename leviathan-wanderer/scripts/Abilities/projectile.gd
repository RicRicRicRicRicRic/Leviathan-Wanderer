#projectile.gd
extends CharacterBody2D
class_name Projectile

static var SPEED: float = 1600.0
static var FIRE_RATE: float = 0.125
var dir: float = 0.0
var spawnPos: Vector2 = Vector2.ZERO
var spawnRot: float = 0.0
var last_shot_time: float = -FIRE_RATE

var hit_count: int = 0
@export var max_hits: int = 3
@export var damage: float = 22.5

static func shoot(start_pos: Vector2, target: Vector2, projectile_scene: PackedScene, shooter: Node) -> void:
	var time_now: float = Time.get_ticks_msec() / 1000.0
	if time_now - shooter.get_meta("last_shot_time", -Projectile.FIRE_RATE) < Projectile.FIRE_RATE:
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
	add_to_group("projectile")
	global_position = spawnPos
	global_rotation = spawnRot
	add_to_group("projectiles")
	for p in get_tree().get_nodes_in_group("projectiles"):
		if p != self:
			add_collision_exception_with(p)

func _physics_process(_delta: float) -> void:
	velocity = Vector2(SPEED, 0).rotated(dir)
	move_and_slide()

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()

		if collider and collider.is_in_group("enemy") and collider.has_method("take_damage"):
			collider.take_damage(damage)
			hit_count += 1

	if hit_count >= max_hits or get_slide_collision_count() > 0:
		queue_free()
