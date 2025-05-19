#chap1_room_scripts
extends Node2D

@onready var blockade_left: Sprite2D = $Sprite2D_block_Left
@onready var blockade_right: Sprite2D = $Sprite2D_block_Right
@onready var blockade_bottom: Sprite2D = $Sprite2D_block_Bottom
@onready var blockade_top: Sprite2D = $Sprite2D_block_Top

@onready var collision_left: CollisionShape2D = $Sprite2D_block_Left/StaticBody2D/CollisionShape2D
@onready var collision_right: CollisionShape2D = $Sprite2D_block_Right/StaticBody2D/CollisionShape2D
@onready var collision_bottom: CollisionShape2D = $Sprite2D_block_Bottom/StaticBody2D/CollisionShape2D
@onready var collision_top: CollisionShape2D = $Sprite2D_block_Top/StaticBody2D/CollisionShape2D

@onready var left_path: Area2D = $Area2D_left
@onready var right_path: Area2D = $Area2D_right
@onready var bottom_path: Area2D = $Area2D_bottom

@onready var reblock: Area2D = $Area2D_reblock
@onready var enemy_counter: Area2D = $Area2D_enemyCounter

var opened_exit_direction: String = ""
var enemies_in_area_count: int = 0
var has_detected_enemy_once: bool = false

func _ready() -> void:
	reblock.body_entered.connect(_on_reblock_body_entered)
	enemy_counter.body_entered.connect(_on_enemy_counter_body_entered)
	enemy_counter.body_exited.connect(_on_enemy_counter_body_exited)

func _set_blockade_active(sprite: Sprite2D, shape: CollisionShape2D, active: bool) -> void:
	if is_instance_valid(sprite):
		sprite.set_deferred("visible", active)
	if is_instance_valid(shape):
		shape.set_deferred("disabled", not active)

func configure_exits(spawn_direction: String) -> void:
	opened_exit_direction = spawn_direction
	match spawn_direction:
		"left":
			_set_blockade_active(blockade_right, collision_right, false)
			right_path.queue_free()
		"right":
			_set_blockade_active(blockade_left, collision_left, false)
			left_path.queue_free()
		"bottom":
			_set_blockade_active(blockade_top, collision_top, false)
			bottom_path.queue_free()
		"top":
			_set_blockade_active(blockade_bottom, collision_bottom, false)

func _on_reblock_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	match opened_exit_direction:
		"left":
			_set_blockade_active(blockade_right, collision_right, true)
		"right":
			_set_blockade_active(blockade_left, collision_left, true)
		"bottom":
			_set_blockade_active(blockade_top, collision_top, true)
		"top":
			_set_blockade_active(blockade_bottom, collision_bottom, true)
	reblock.queue_free()

func _on_enemy_counter_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		enemies_in_area_count += 1
		has_detected_enemy_once = true

func _on_enemy_counter_body_exited(body: Node) -> void:
	if body.is_in_group("enemy"):
		enemies_in_area_count -= 1
		if enemies_in_area_count <= 0 and has_detected_enemy_once:
			var actual_enemies = get_enemies_in_area()
			if actual_enemies.is_empty():
				call_deferred("remove_cleared_blockades")
			else:
				enemies_in_area_count = actual_enemies.size()

func get_enemies_in_area() -> Array:
	var enemies = []
	if is_instance_valid(enemy_counter):
		for body in enemy_counter.get_overlapping_bodies():
			if is_instance_valid(body) and body.is_in_group("enemy"):
				enemies.append(body)
	return enemies

func remove_cleared_blockades() -> void:
	enemy_counter.queue_free()
	if is_instance_valid(blockade_left):
		blockade_left.queue_free()
	if is_instance_valid(blockade_right):
		blockade_right.queue_free()
	if is_instance_valid(blockade_bottom):
		blockade_bottom.queue_free()
	if opened_exit_direction == "bottom":
		if is_instance_valid(blockade_top):
			blockade_top.queue_free()
