# projectile.gd
extends RigidBody2D
class_name Projectile

static var SPEED: float = 1600.0
static var BASE_FIRE_RATE: float = 0.125 
static var MANA_COST: int = 12
static var BASE_COMBO_VALUE: int = 15

var dir: float = 0.0
var spawnPos: Vector2 = Vector2.ZERO
var spawnRot: float = 0.0
var hit_count: int = 0
@export var max_hits: int = 10
@export var damage: float = 470

@onready var delete_timer: Timer = $Timer
@onready var anisprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D

static func shoot(start_pos: Vector2, target: Vector2, projectile_scene: PackedScene, shooter: Node) -> void:
	var time_now: float = Time.get_ticks_msec() / 1000.0
	
	var effective_fire_rate = Projectile.BASE_FIRE_RATE / GlobalGameState.projectile_fire_rate_multiplier_effect

	var last_shot_time: float = shooter.get_meta("last_shot_time", -effective_fire_rate) as float

	if time_now - last_shot_time < effective_fire_rate:
		return

	var effective_mana_cost = int(Projectile.MANA_COST * GlobalGameState.projectile_mana_cost_multiplier)

	if shooter.current_mana < effective_mana_cost:
		return
	else:
		shooter.current_mana -= effective_mana_cost 
		shooter.update_mana_bar()

	shooter.set_meta("last_shot_time", time_now)

	var proj: Projectile = projectile_scene.instantiate() as Projectile
	var angle: float = (target - start_pos).angle()

	var spread_angle_rad: float = GlobalGameState.projectile_spread_angle_rad
	if spread_angle_rad != 0.0:
		angle += randf_range(-spread_angle_rad / 2.0, spread_angle_rad / 2.0)

	proj.spawnPos = start_pos
	proj.dir = angle
	proj.spawnRot = angle
	proj.rotation = angle
	
	if proj.has_node("AnimatedSprite2D"):
		var sprite: AnimatedSprite2D = proj.get_node("AnimatedSprite2D") as AnimatedSprite2D
		sprite.scale = Vector2(1,1) * GlobalGameState.projectile_scale_multiplier
		if proj.has_node("CollisionShape2D"):
			var shape = proj.get_node("CollisionShape2D").shape as RectangleShape2D 
			if shape:
				shape.size = shape.size * GlobalGameState.projectile_scale_multiplier
		
		if proj.has_node("GPUParticles2D"):
			var particles: GPUParticles2D = proj.get_node("GPUParticles2D") as GPUParticles2D
			particles.scale = Vector2(1,1) * GlobalGameState.projectile_scale_multiplier

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
	if (body.is_in_group("enemy") or body.is_in_group("enemy_shield")) and body.has_method("take_damage"):
		var effective_damage: float = damage * GlobalGameState.projectile_damage_multiplier
		body.take_damage(effective_damage) 
		
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node and player_node.has_method("add_combo"):
			var combo_modifier: float = GlobalGameState.projectile_combo_multiplier
			player_node.add_combo(int(Projectile.BASE_COMBO_VALUE * combo_modifier))

	anisprite.queue_free()
	collider.queue_free()
	$GPUParticles2D.emitting = false
	if not $GPUParticles2D.emitting:
		delete_timer.start()

func _on_delete_timer_timeout() -> void:
	queue_free()
