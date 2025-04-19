# slug_healing_orbs.gd
extends RigidBody2D

@export var min_speed: float = 175.0
@export var max_speed: float = 225.0
@export var homing_speed: float = 600.0
@export var heal_amount: float = 65.0
@export var scan_radius: float = 550.0

@onready var despawn_timer: Timer = $Timer
@onready var sprite: Sprite2D = $Sprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D
var homing_target: Node2D = null
var _removed: bool = false

func _ready() -> void:
	randomize()
	gravity_scale = 0.0
	contact_monitor = true
	max_contacts_reported = 1

	var initial_speed: float = randf_range(min_speed, max_speed)
	var angle: float = randf() * TAU
	linear_velocity = Vector2(cos(angle), sin(angle)) * initial_speed

	despawn_timer.timeout.connect(_on_despawn_timer_timeout)
	despawn_timer.start()

func _physics_process(_delta: float) -> void:
	if homing_target != null:
		if not is_instance_valid(homing_target) or homing_target.health >= homing_target.max_health:
			homing_target = null

	if homing_target == null:
		var nearest_dist := INF
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if enemy.health < enemy.max_health:
				var d := global_position.distance_to(enemy.global_position)
				if d <= scan_radius and d < nearest_dist:
					nearest_dist = d
					homing_target = enemy

	if homing_target != null:
		var dir_vec: Vector2 = (homing_target.global_position - global_position).normalized()
		linear_velocity = dir_vec * homing_speed

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	for i in range(state.get_contact_count()):
		var collider_obj: Object = state.get_contact_collider_object(i)
		if collider_obj != null and (collider_obj as Node2D).is_in_group("enemy") and (collider_obj as Node2D).has_method("heal") and (collider_obj as Node2D).health < (collider_obj as Node2D).max_health:
			(collider_obj as Node2D).heal(heal_amount)
			remove_orb()
			return

func _on_despawn_timer_timeout() -> void:
	remove_orb()

func remove_orb() -> void:
	if _removed:
		return
	_removed = true
	if is_instance_valid(sprite):sprite.queue_free()
	if is_instance_valid(collider):collider.queue_free()
	$GPUParticles2D.emitting = false
	if not $GPUParticles2D.emitting:
		var delay_timer: Timer = Timer.new()
		delay_timer.wait_time = 3
		delay_timer.one_shot = true
		delay_timer.timeout.connect(func(): queue_free())
		add_child(delay_timer)
