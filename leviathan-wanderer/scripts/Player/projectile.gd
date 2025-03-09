#projectile.gd
extends "res://scripts/Interpolation/Interpolate.gd"
class_name Projectile

@export var SPEED = 900
@export var fire_rate: float = 0.1  
var dir: float = 0.0
var spawnPos: Vector2
var spawnRot: float

static func shoot(start_pos: Vector2, target: Vector2, projectile_scene: PackedScene, shooter: Node) -> void:
	var proj = projectile_scene.instantiate()
	var angle = (target - start_pos).angle()
	proj.spawnPos = start_pos
	proj.dir = angle
	proj.spawnRot = angle
	proj.rotation = angle

	if target.x < start_pos.x and proj.has_node("AnimatedSprite2D"):
		proj.get_node("AnimatedSprite2D").flip_v = true

	proj.add_collision_exception_with(shooter)
	var scene = shooter.get_tree().current_scene
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
