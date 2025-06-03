# larvae_egg.gd
extends RigidBody2D

@onready var particles2D_spawn: GPUParticles2D = $GPUParticles2D_spawn
@onready var particles2D_death: GPUParticles2D = $GPUParticles2D_death
@onready var hatch_timer: Timer = $hatch_timer
@onready var sprite: Sprite2D = $Sprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D

@export var larvaes: PackedScene = preload("res://scene/enemyscene/VespulaRegin-boss/wasp_larvae.tscn")

var _boss_defeated_flag: bool = false 

func _ready() -> void:
	hatch_timer.start()
	hatch_timer.timeout.connect(_on_hatch_timer_timeout)

	if is_instance_valid(particles2D_spawn):
		particles2D_spawn.visible = true
		particles2D_spawn.emitting = true
		particles2D_spawn.restart()

	if is_instance_valid(particles2D_death):
		particles2D_death.finished.connect(_on_death_particles_finished)


	var boss_node = get_tree().get_first_node_in_group("boss")
	if boss_node and is_instance_valid(boss_node):
		boss_node.boss_defeated.connect(_on_boss_defeated)

func _on_hatch_timer_timeout() -> void:
	sprite.visible = false
	

	if is_instance_valid(collider):
		collider.disabled = true

	if is_instance_valid(particles2D_death):
		particles2D_death.visible = true
		particles2D_death.emitting = true
		particles2D_death.restart()

	if not _boss_defeated_flag:
		var base_spawn_position: Vector2 = global_position 
		var spread_radius: float = 50.0 
		var num_larvae_to_spawn: int = 3

		for i in range(num_larvae_to_spawn):
			if larvaes != null:
				var new_larvae = larvaes.instantiate()
				if new_larvae != null:
					var angle = (float(i) / num_larvae_to_spawn) * TAU 
					var offset = Vector2(cos(angle), sin(angle)) * spread_radius

					new_larvae.global_position = base_spawn_position + offset

					get_parent().add_child(new_larvae)

func _on_death_particles_finished() -> void:
	queue_free()

func _on_boss_defeated() -> void:
	_boss_defeated_flag = true
	if hatch_timer.time_left > 0: 
		hatch_timer.stop()
	_on_hatch_timer_timeout() 
