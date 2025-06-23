#nudibranch.gd
extends "res://scripts/Utility/Interpolate.gd"

@onready var visuals: Node2D = $Node2D
@onready var anim: AnimatedSprite2D = $Node2D/AnimatedSprite2D
@onready var collider: CollisionPolygon2D = $Collider
@onready var ray_wall: RayCast2D = $Node2D/RayCast2D_wall
@onready var ray_fall: RayCast2D = $Node2D/RayCast2D_fall
@onready var damage_area: Area2D = $Node2D/Area2D_DamageArea
@onready var turn_timer: Timer = $Timer
@onready var poison_timer: Timer = $Timer_poision
@onready var player: Node = null
@onready var health_bar: Control = $Control

@export var speed: float = 200.0
@export var max_health: int = 900
@export var knockback_strength: float = 1200.0
@export var detection_range: float = 400.0
@export var full_visibility_range: float = 150
@export var visibility_lerp_speed: float = 5.0
@export var poison_damage_per_tick: int = 5
@export var poison_tick_interval: float = 0.5

var direction: Vector2 = Vector2.RIGHT
var is_turning_condition_met: bool = false
var is_currently_turning: bool = false
var health: int = 0
var is_dying: bool = false
var current_alpha: float = 0.0
var is_revealing_on_damage: bool = false
var death_animation_completed: bool = false

var poisoned_players: Dictionary = {}

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position
	turn_timer.connect("timeout", _on_turn_timer_timeout)
	anim.animation_finished.connect(_on_animation_finished)
	damage_area.body_entered.connect(_on_DamageArea_body_entered)
	health = max_health
	add_to_group("enemy")
	
	player = get_tree().get_first_node_in_group("player")
	if player:
		ray_wall.add_exception(player)
		ray_fall.add_exception(player)
	
	visuals.modulate.a = 0.0
	health_bar.modulate.a = 0.0
	current_alpha = 0.0

func _physics_process(delta: float) -> void:
	previous_position = global_position
	if not is_dying:
		if not is_on_floor():
			velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
		else:
			velocity.y = 0.0

		ray_wall.force_raycast_update()
		ray_fall.force_raycast_update()

		var wall_ahead: bool = ray_wall.is_colliding()
		var falling_edge: bool = not ray_fall.is_colliding()
		var new_turning_condition_met: bool = wall_ahead or falling_edge

		if new_turning_condition_met and not is_turning_condition_met and turn_timer.is_stopped():
			velocity.x = 0
			anim.play("iddle")
			turn_timer.start()
			is_currently_turning = true
		elif not new_turning_condition_met and is_currently_turning:
			pass

		is_turning_condition_met = new_turning_condition_met

		if not is_currently_turning:
			velocity.x = direction.x * speed
			anim.play("walk")
			if direction.x == -1:
				visuals.scale.x = 1.0
				collider.scale.x = 1.0
			else:
				visuals.scale.x = -1.0
				collider.scale.x = -1.0

		move_and_slide()

		if player:
			var distance_to_player = global_position.distance_to(player.global_position)
			var target_alpha_from_proximity: float
			
			if distance_to_player <= full_visibility_range:
				target_alpha_from_proximity = 1.0
			elif distance_to_player >= detection_range:
				target_alpha_from_proximity = 0.0
			else:
				target_alpha_from_proximity = 1.0 - (distance_to_player - full_visibility_range) / (detection_range - full_visibility_range)
				target_alpha_from_proximity = clamp(target_alpha_from_proximity, 0.0, 1.0)
			
			if is_revealing_on_damage:
				current_alpha = lerp(current_alpha, 1.0, delta * visibility_lerp_speed * 2.0)
				if current_alpha > 0.99:
					current_alpha = 1.0
					is_revealing_on_damage = false
			else:
				current_alpha = lerp(current_alpha, target_alpha_from_proximity, delta * visibility_lerp_speed)
			
			visuals.modulate.a = current_alpha
			health_bar.modulate.a = current_alpha
	else:
		velocity.y = 0.0
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var players_to_remove: Array = []

	for p_node in poisoned_players.keys():
		var poison_data = poisoned_players[p_node]
		
		if not is_instance_valid(p_node):
			players_to_remove.append(p_node)
			continue

		if current_time >= poison_data.last_tick_time + poison_tick_interval:
			if p_node.has_method("take_damage"):
				p_node.take_damage(poison_damage_per_tick)
			poison_data.last_tick_time = current_time

		if current_time >= poison_data.end_time:
			players_to_remove.append(p_node)
	
	for p_node in players_to_remove:
		poisoned_players.erase(p_node)
	
	if is_dying and death_animation_completed and poisoned_players.is_empty():
		queue_free()


func _on_turn_timer_timeout() -> void:
	direction *= -1
	is_currently_turning = false

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	
	is_revealing_on_damage = true

	if health <= 0 and not is_dying:
		is_dying = true
		velocity = Vector2.ZERO
		collider.set_deferred("disabled", true)
		damage_area.set_deferred("monitoring", false)
		visuals.modulate.a = 1.0
		health_bar.modulate.a = 1.0
		
		death_animation_completed = false
		
		anim.play("death")


func _on_animation_finished() -> void:
	if is_dying and anim.animation == "death":
		death_animation_completed = true

func knockback(force: Vector2) -> void:
	if not is_dying:
		velocity += force

func _on_DamageArea_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var diff: Vector2 = body.global_position - global_position
		var knock_dir: Vector2
		if diff.length() > 0:
			knock_dir = diff.normalized()
		else:
			knock_dir = Vector2(-direction.x, 0)
		var knockback_force: Vector2 = knock_dir * knockback_strength
		
		if body.has_method("take_damage"):
			body.take_damage(45)
		if body.has_method("knockback"):
			body.knockback(knockback_force)
		
		var current_time = Time.get_ticks_msec() / 1000.0
		var poison_duration = poison_timer.wait_time
		
		if poisoned_players.has(body):
			poisoned_players[body].end_time = current_time + poison_duration
		else:
			poisoned_players[body] = {
				"end_time": current_time + poison_duration,
				"last_tick_time": current_time
			}
