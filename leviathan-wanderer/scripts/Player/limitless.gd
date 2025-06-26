# limitless.gd
extends Area2D

signal technique_ended
signal cooldown_finished

@onready var limitless_technique_duration_timer: Timer = $Timer_Duration
@onready var limitless_technique_cooldown_timer: Timer = $Timer_Cooldown

var _original_velocities: Dictionary = {}
var is_active: bool = false
var is_on_cooldown: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_on_body_exited)
	
	limitless_technique_duration_timer.timeout.connect(_on_duration_timer_timeout)
	limitless_technique_cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)

	monitoring = false
	set_deferred("monitorable", false)

func activate_technique() -> void:
	if is_on_cooldown:
		return

	is_active = true
	is_on_cooldown = true

	monitoring = true
	set_deferred("monitorable", true)

	limitless_technique_duration_timer.start()
	
	_process_existing_bodies_on_activate()

func can_activate() -> bool:
	return not is_on_cooldown

func _process_existing_bodies_on_activate() -> void:
	var overlapping_bodies = get_overlapping_bodies()
	for body in overlapping_bodies:
		if (body.is_in_group("enemy") or body.is_in_group("enemy_proj")) and is_instance_valid(body):
			_on_body_entered(body)

func _on_body_entered(body: Node) -> void:
	if is_active and (body.is_in_group("enemy") or body.is_in_group("enemy_proj")):
		if is_instance_valid(body) and not _original_velocities.has(body):
			body.set_process(false)
			body.set_physics_process(false)

			if body is RigidBody2D:
				_original_velocities[body] = {
					"linear": body.linear_velocity,
					"angular": body.angular_velocity
				}
				body.linear_velocity = Vector2.ZERO
				body.angular_velocity = 0.0
			elif body is CharacterBody2D:
				_original_velocities[body] = {
					"velocity": body.velocity
				}
				body.velocity = Vector2.ZERO
			
			for child in body.get_children():
				if child is AnimatedSprite2D:
					child.stop()
				elif child is AnimationPlayer:
					child.stop(true) 
				elif child is Timer:
					child.stop()

func _on_on_body_exited(body: Node) -> void:
	if is_active and _original_velocities.has(body):
		_resume_entity(body)
		_original_velocities.erase(body)


func _on_duration_timer_timeout() -> void:
	is_active = false
	monitoring = false
	set_deferred("monitorable", false)

	reset_all_paused_entities()
	technique_ended.emit()

	is_on_cooldown = true
	limitless_technique_cooldown_timer.start()


func _on_cooldown_timer_timeout() -> void:
	is_on_cooldown = false
	cooldown_finished.emit()


func reset_all_paused_entities() -> void:
	for body in _original_velocities.keys():
		if is_instance_valid(body):
			_resume_entity(body)
	_original_velocities.clear()


func _resume_entity(body: Node) -> void:
	body.set_process(true)
	body.set_physics_process(true)

	if _original_velocities.has(body):
		var stored_vel = _original_velocities[body]
		if body is RigidBody2D:
			body.linear_velocity = stored_vel["linear"]
			body.angular_velocity = stored_vel["angular"]
		elif body is CharacterBody2D:
			body.velocity = stored_vel["velocity"]
	else: 
		if body is RigidBody2D:
			body.linear_velocity = Vector2.ZERO 
			body.angular_velocity = 0.0
		elif body is CharacterBody2D:
			body.velocity = Vector2.ZERO
	
	for child in body.get_children():
		if child is AnimatedSprite2D:
			child.play()
		elif child is AnimationPlayer:
			child.play()
		elif child is Timer:
			child.start()
