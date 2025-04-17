# slug_healing_orbs.gd
extends RigidBody2D

@export var min_speed: float = 150.0
@export var max_speed: float = 200.0
@export var homing_speed: float = 600.0   
@export var heal_amount: float = 65.0
@export var scan_radius: float = 450.0

@onready var despawn_timer: Timer = $Timer
var homing_target: Node2D = null

func _ready() -> void:
	randomize()
	gravity_scale = 0.0  
	contact_monitor = true
	max_contacts_reported = 1

	var speed = randf_range(min_speed, max_speed)
	var angle = randf() * TAU
	linear_velocity = Vector2(cos(angle), sin(angle)) * speed

	despawn_timer.timeout.connect(_on_despawn_timer_timeout)
	despawn_timer.start()

func _physics_process(_delta: float) -> void:
	if homing_target:
		if not is_instance_valid(homing_target) or homing_target.health >= homing_target.max_health:
			homing_target = null

	if homing_target == null:
		var space_state = get_world_2d().direct_space_state
		var shape = CircleShape2D.new()
		shape.radius = scan_radius
		var params = PhysicsShapeQueryParameters2D.new()
		params.set_shape(shape)
		params.transform = Transform2D(0, global_position)
		params.collide_with_bodies = true
		params.collide_with_areas = false
		params.exclude = [self]

		var results = space_state.intersect_shape(params)
		var nearest_dist = INF
		for result in results:
			var body = result.collider
			if body.is_in_group("enemy") and body.has_method("heal") and body.health < body.max_health:
				var d = global_position.distance_to(body.global_position)
				if d < nearest_dist:
					nearest_dist = d
					homing_target = body

	if homing_target:
		var dir = (homing_target.global_position - global_position).normalized()
		linear_velocity = dir * homing_speed

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if collider and collider.is_in_group("enemy") and collider.has_method("heal") and collider.health < collider.max_health:
			collider.heal(heal_amount)
			queue_free()
			return

func _on_despawn_timer_timeout() -> void:
	queue_free()
