extends CharacterBody2D

@export var termite_scene: PackedScene = preload("res://scene/enemyscene/termite/termite.tscn")
@export var health: int
@export var max_health: int = 350
@export var initial_rotation_degrees: float = 0.0

var termite_count: int = 0
@export var max_termite_spawn: int = 3

@onready var timer: Timer =$Timer
@onready var shroom_anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar: Control = $Control
@onready var collider: CollisionPolygon2D = $CollisionPolygon2D
@onready var area2D: Area2D = $Area2D
@onready var spawn_point: Marker2D = $AnimatedSprite2D/Marker2D
@onready var particles_spawn: GPUParticles2D = $AnimatedSprite2D/GPUParticles2D_spawn
@onready var particles_death: GPUParticles2D = $CollisionPolygon2D/GPUParticles2D_death

var is_dying: bool = false

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	timer.timeout.connect(_on_timer_timeout)
	_update_hp_bar()
	shroom_anim.rotation_degrees = initial_rotation_degrees
	collider.rotation_degrees = initial_rotation_degrees

	hp_bar.visible = false
	shroom_anim.visible = false
	collider.disabled = true

	area2D.body_entered.connect(_on_area2D_body_entered)

func spawn_termite_at_position(global_spawn_position: Vector2) -> void:
	var new_termite: CharacterBody2D = termite_scene.instantiate() as CharacterBody2D
	var target_parent: Node = get_parent()

	if target_parent:
		new_termite.position = target_parent.to_local(global_spawn_position)
		target_parent.call_deferred("add_child", new_termite)
	else:
		new_termite.position = global_spawn_position
		get_tree().get_root().call_deferred("add_child", new_termite)

	particles_spawn.global_position = global_spawn_position
	particles_spawn.restart()

	if new_termite.has_signal("died"):
		new_termite.died.connect(_on_termite_died)
	else:
		new_termite.tree_exited.connect(_on_termite_died)

	termite_count += 1


func _on_timer_timeout() -> void:
	if termite_count < max_termite_spawn:
		spawn_termite_at_position(spawn_point.global_position)
		timer.start()
		shroom_anim.play("tussle")
	else:
		timer.start()


func take_damage(amount: float) -> void:
	health -= int(amount)
	_update_hp_bar()

	if health <= 0 and not is_dying:
		timer.stop()
		is_dying = true
		shroom_anim.visible = false
		if is_instance_valid(hp_bar):
			hp_bar.queue_free()
		collider.set_deferred("disabled", true)

		particles_death.emitting = true
		particles_death.finished.connect(_on_death_particles_finished)

		var base_spawn_position: Vector2 = spawn_point.global_position
		var spread_offset: float = 75.0

		for i: int in range(3):
			var offset_direction: Vector2 = Vector2(cos(i * PI * 2 / 3), sin(i * PI * 2 / 3)).normalized()
			var final_spawn_position: Vector2 = base_spawn_position + offset_direction * spread_offset

			var new_termite_on_death: CharacterBody2D = termite_scene.instantiate() as CharacterBody2D

			var target_parent: Node = get_parent()
			if target_parent:
				new_termite_on_death.position = target_parent.to_local(final_spawn_position)
				target_parent.call_deferred("add_child", new_termite_on_death)
			else:
				new_termite_on_death.position = final_spawn_position
				get_tree().get_root().call_deferred("add_child", new_termite_on_death)

			if new_termite_on_death.has_signal("died"):
				new_termite_on_death.died.connect(_on_termite_died)
			else:
				new_termite_on_death.tree_exited.connect(_on_termite_died)
			termite_count += 1

func _update_hp_bar() -> void:
	if hp_bar is ProgressBar:
		(hp_bar as ProgressBar).value = health
		(hp_bar as ProgressBar).max_value = max_health
	else:
		var progress_bar_child: ProgressBar = hp_bar.find_child("ProgressBar") as ProgressBar
		if progress_bar_child and progress_bar_child is ProgressBar:
			progress_bar_child.value = health
			progress_bar_child.max_value = max_health

func _on_area2D_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		timer.start()
		hp_bar.visible = true
		shroom_anim.visible = true
		collider.set_deferred("disabled", false)
		if is_instance_valid(area2D):
			area2D.queue_free()

func _on_termite_died() -> void:
	termite_count -= 1

func _on_death_particles_finished() -> void:
	queue_free()
