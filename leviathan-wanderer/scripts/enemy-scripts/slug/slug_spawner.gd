# slug_spawner.gd
extends Area2D

@export var spawn_ammount: int = 2
@export var enemy: PackedScene = preload("res://scene/enemyscene/slug/slug.tscn")
@export var random_spread_radius: float = 100.0
@export var delete: bool = true

@onready var marker: Marker2D = $Marker2D
@onready var collider: CollisionPolygon2D = $CollisionPolygon2D
@onready var timer: Timer = $Timer

var is_active: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exit)
	if !delete:
		timer.timeout.connect(_on_timer_timeout)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and !is_active:
		is_active = true

		for i in range(spawn_ammount):
			spawn_enemy()

		if delete:
			call_deferred("queue_free")
		else:
			timer.start()

func _on_body_exit(body: Node2D) -> void:
	if body.is_in_group("player"):
		if !delete:
			timer.stop()
			is_active = false

func _on_timer_timeout() -> void:
	for i in range(spawn_ammount):
		spawn_enemy()
		timer.start()

func spawn_enemy() -> void:
	if enemy:
		var enemy_instance = enemy.instantiate()
		var base_position = marker.global_position
		var random_offset = Vector2(
			randf_range(-random_spread_radius, random_spread_radius),
			randf_range(-random_spread_radius, random_spread_radius)
		)
		var final_position = base_position + random_offset
		enemy_instance.global_position = final_position
		get_parent().call_deferred("add_child", enemy_instance)
