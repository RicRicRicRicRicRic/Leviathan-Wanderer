#urchin.gd
extends CharacterBody2D

@onready var dash_delay: Timer = $Timer
@onready var player: Node = null
@onready var anim: AnimatedSprite2D = $Node2D/AnimatedSprite2D
@onready var damage_area: Area2D = $Area2D
@onready var visuals: Node2D = $Node2D

@export var urchin_projectile: PackedScene = preload("res://scene/enemyscene/urchin/proj_urchin.tscn")
@export var max_health: int = 450
@export var follow_speed: float = 80.0
@export var dash_speed: float = 1000.0
@export var dash_total_duration: float = 0.2
@export var dash_detection_range: float = 350.0
@export var normal_damage: int = 15
@export var dash_damage: int = 55
@export var normal_knockback: float = 300.0
@export var dash_knockback: float = 1500.0
@export var dash_rotation_speed: float = 1000.0
@export var rotation_lerp_speed: float = 10.0
@export var throb_scale_min: float = 0.9
@export var throb_scale_max: float = 1.1
@export var throb_speed: float = 2.5
@export var projectiles_on_death: int = 8

var health: int = 0
var current_state: State = State.FOLLOWING
var dash_vector: Vector2 = Vector2.ZERO
var dash_time_elapsed: float = 0.0
var current_rotation_lerp_target: float = 0.0
var throb_time: float = 0.0

enum State {
	FOLLOWING,
	PREPARING_DASH,
	DASHING,
	DYING
}

func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	
	randomize()
	throb_time = randf() * (2 * PI)

	player = get_tree().get_first_node_in_group("player")
	dash_delay.one_shot = true
	dash_delay.autostart = false
	dash_delay.connect("timeout", _on_dash_delay_timeout)
	damage_area.body_entered.connect(_on_DamageArea_body_entered)


func _physics_process(delta: float) -> void:
	if current_state == State.DYING:
		velocity = Vector2.ZERO
		return

	match current_state:
		State.FOLLOWING:
			if player and is_instance_valid(player):
				var direction_to_player = (player.global_position - global_position).normalized()
				velocity = direction_to_player * follow_speed
				
				var distance_to_player = global_position.distance_to(player.global_position)
				if distance_to_player <= dash_detection_range:
					current_state = State.PREPARING_DASH
					velocity = Vector2.ZERO
					dash_delay.start()
			else:
				velocity = Vector2.ZERO
			current_rotation_lerp_target = 0.0
			
			throb_time += delta * throb_speed
			var scale_factor = lerp(throb_scale_min, throb_scale_max, (sin(throb_time) + 1.0) / 2.0)
			visuals.scale = Vector2(scale_factor, scale_factor)

		State.PREPARING_DASH:
			current_rotation_lerp_target = 0.0
			visuals.scale = Vector2(1.0, 1.0)
			throb_time = 0.0
			pass

		State.DASHING:
			dash_time_elapsed += delta
			current_rotation_lerp_target = dash_rotation_speed
			visuals.scale = Vector2(1.0, 1.0)
			throb_time = 0.0
			if dash_time_elapsed >= dash_total_duration:
				current_state = State.FOLLOWING
				velocity = Vector2.ZERO

	anim.rotation_degrees += lerp(0.0, current_rotation_lerp_target, delta * rotation_lerp_speed) * delta

	move_and_slide()


func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	
	if health <= 0:
		_die()

func _die() -> void:
	current_state = State.DYING
	velocity = Vector2.ZERO
	set_physics_process(false)
	
	if get_node_or_null("Collider") != null:
		var collider_node = get_node("Collider")
		if collider_node is CollisionShape2D or collider_node is CollisionPolygon2D:
			collider_node.set_deferred("disabled", true)
	
	if damage_area:
		damage_area.set_deferred("monitoring", false)
		damage_area.set_deferred("monitorable", false)
	
	visuals.scale = Vector2(1.0, 1.0)
	
	_shoot_projectiles_on_death()

	queue_free()


func _on_dash_delay_timeout() -> void:
	if player and is_instance_valid(player):
		dash_vector = (player.global_position - global_position).normalized()
		current_state = State.DASHING
		dash_time_elapsed = 0.0
		velocity = dash_vector * dash_speed
	else:
		current_state = State.FOLLOWING

func _on_DamageArea_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var damage_to_deal: int
		var knockback_strength_value: float
		
		if current_state == State.DASHING:
			damage_to_deal = dash_damage
			knockback_strength_value = dash_knockback
		else:
			damage_to_deal = normal_damage
			knockback_strength_value = normal_knockback
		
		var diff: Vector2 = body.global_position - global_position
		var knock_dir: Vector2
		if diff.length() > 0:
			knock_dir = diff.normalized()
		else:
			knock_dir = Vector2(1, 0)
		
		var knockback_force: Vector2 = knock_dir * knockback_strength_value
		
		if body.has_method("take_damage"):
			body.take_damage(damage_to_deal)
		if body.has_method("knockback"):
			body.knockback(knockback_force)

func _shoot_projectiles_on_death() -> void:
	if not urchin_projectile or projectiles_on_death <= 0:
		return

	var angles_degrees: Array = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]

	for i in range(projectiles_on_death):
		if i >= angles_degrees.size():
			break

		var projectile_instance = urchin_projectile.instantiate()
		if not projectile_instance:
			continue

		get_parent().call_deferred("add_child", projectile_instance)
		projectile_instance.global_position = global_position

		var current_angle_degrees = angles_degrees[i]
		var direction_vector = Vector2.RIGHT.rotated(deg_to_rad(current_angle_degrees))

		projectile_instance.call_deferred("set_initial_direction", direction_vector)
		projectile_instance.set_deferred("rotation", direction_vector.angle())