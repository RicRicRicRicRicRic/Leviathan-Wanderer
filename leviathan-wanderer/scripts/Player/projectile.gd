#projectile.gd
extends CharacterBody2D
class_name Projectile

static var SPEED: float = 1500.0
static var FIRE_RATE: float = 0.15
var dir: float = 0.0
var spawnPos: Vector2 = Vector2.ZERO
var spawnRot: float = 0.0
var last_shot_time: float = -FIRE_RATE

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
	global_position = spawnPos
	global_rotation = spawnRot
	add_to_group("projectiles")
	for p in get_tree().get_nodes_in_group("projectiles"):
		if p != self:
			add_collision_exception_with(p)

func _physics_process(_delta: float) -> void:
	velocity = Vector2(SPEED, 0).rotated(dir)
	move_and_slide()
	if get_slide_collision_count() > 0:
		queue_free()
