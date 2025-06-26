# chap3_roomscripts.gd
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

var room_paths: Array[String] = [
	"res://scene/Chapter3/chap_3_room_a.tscn",
	"res://scene/Chapter3/chap_3_room_b.tscn",
	"res://scene/Chapter3/chap_3_room_c.tscn",
	"res://scene/Chapter3/chap_3_room_d.tscn",
]

var final_room_path: String = "res://scene/Chapter3/chap_3_final_room.tscn"
var opened_exit_direction: String = ""
var enemies_in_area_count: int = 0
var has_detected_enemy_once: bool = false
var room_spawned: bool = false
var spawned_from_bottom: bool = false

var offset_left: float = -3060.0
var offset_right: float = 3060.0
var offset_bottom: float = 1870.0

static var defeated_rooms_count: int = 0
const DEFEATED_ROOMS_THRESHOLD: int = 1

const THIS_SCRIPT = preload("res://scripts/Chapter3/chap3_roomscripts.gd")

func _ready() -> void:
	randomize()
	if not is_instance_valid(blockade_left):
		push_error("blockade_left missing in %s" % name)
	if not is_instance_valid(blockade_right):
		push_error("blockade_right missing in %s" % name)
	if not is_instance_valid(blockade_bottom):
		push_error("blockade_bottom missing in %s" % name)
	if not is_instance_valid(blockade_top):
		push_error("blockade_top missing in %s" % name)
	if not is_instance_valid(collision_left):
		push_error("collision_left missing in %s" % name)
	if not is_instance_valid(collision_right):
		push_error("collision_right missing in %s" % name)
	if not is_instance_valid(collision_bottom):
		push_error("collision_bottom missing in %s" % name)
	if not is_instance_valid(collision_top):
		push_error("collision_top missing in %s" % name)
	if not is_instance_valid(left_path):
		push_error("left_path missing in %s" % name)
	if not is_instance_valid(right_path):
		push_error("right_path missing in %s" % name)
	if not is_instance_valid(bottom_path):
		push_error("bottom_path missing in %s" % name)
	if not is_instance_valid(reblock):
		push_error("reblock missing in %s" % name)
	if not is_instance_valid(enemy_counter):
		push_error("enemy_counter missing in %s" % name)

	disable_all_blockades()
	left_path.connect("body_entered", Callable(self, "_on_path_entered").bind("left"))
	right_path.connect("body_entered", Callable(self, "_on_path_entered").bind("right"))
	bottom_path.connect("body_entered", Callable(self, "_on_path_entered").bind("bottom"))
	enemy_counter.connect("body_entered", Callable(self, "_on_enemy_entered"))
	enemy_counter.connect("body_exited", Callable(self, "_on_enemy_exited"))

func disable_all_blockades() -> void:
	if is_instance_valid(blockade_left):
		blockade_left.visible = false
	if is_instance_valid(collision_left):
		collision_left.set_deferred("disabled", true)
	if is_instance_valid(blockade_right):
		blockade_right.visible = false
	if is_instance_valid(collision_right):
		collision_right.set_deferred("disabled", true)
	if is_instance_valid(blockade_bottom):
		blockade_bottom.visible = false
	if is_instance_valid(collision_bottom):
		collision_bottom.set_deferred("disabled", true)
	if is_instance_valid(blockade_top):
		blockade_top.visible = false
	if is_instance_valid(collision_top):
		collision_top.set_deferred("disabled", true)

func _on_path_entered(body: Node, exit_direction_from_current_room: String) -> void:
	if not body.is_in_group("player") or room_spawned:
		return
	room_spawned = true
	opened_exit_direction = exit_direction_from_current_room
	spawned_from_bottom = (exit_direction_from_current_room == "bottom")
	
	call_deferred("handle_initial_blockades", exit_direction_from_current_room)
	var path: String = get_non_repeating_room()
	var packed: PackedScene = ResourceLoader.load(path) as PackedScene
	call_deferred("_do_spawn", packed, exit_direction_from_current_room)

func get_non_repeating_room() -> String:
	if defeated_rooms_count >= DEFEATED_ROOMS_THRESHOLD:
		return final_room_path
	var current_room_path: String = get_scene_file_path()
	var available_rooms: Array[String] = room_paths.filter(func(path): return path != current_room_path)
	if available_rooms.is_empty():
		push_warning("No available rooms to spawn, falling back to random room")
		return room_paths[randi() % room_paths.size()]
	return available_rooms[randi() % available_rooms.size()]

func handle_initial_blockades(direction: String) -> void:
	match direction:
		"left":
			enable_blockade("right")
			enable_blockade("bottom")
			enable_blockade("top")
			free_blockade("left")
		"right":
			enable_blockade("left")
			enable_blockade("bottom")
			enable_blockade("top")
			free_blockade("right")
		"bottom":
			enable_blockade("left")
			enable_blockade("right")
			enable_blockade("top")
			free_blockade("bottom")

func _do_spawn(packed: PackedScene, exit_direction_from_current_room: String) -> void:
	var new_room: Node2D = packed.instantiate()
	add_child(new_room)

	var entry_direction_for_new_room_relative: String = ""
	match exit_direction_from_current_room:
		"left":
			entry_direction_for_new_room_relative = "right"
		"right":
			entry_direction_for_new_room_relative = "left"
		"bottom":
			entry_direction_for_new_room_relative = "top"
		"top":
			entry_direction_for_new_room_relative = "bottom"

	if new_room.get_script() == THIS_SCRIPT:
		new_room.opened_exit_direction = entry_direction_for_new_room_relative
		new_room.spawned_from_bottom = (entry_direction_for_new_room_relative == "bottom")
	
	match exit_direction_from_current_room:
		"left":
			new_room.position = Vector2(offset_left, 0)
		"right":
			new_room.position = Vector2(offset_right, 0)
		"bottom":
			new_room.position = Vector2(0, offset_bottom)

	match exit_direction_from_current_room:
		"left":
			if is_instance_valid(left_path):
				left_path.queue_free()
		"right":
			if is_instance_valid(right_path):
				right_path.queue_free()
		"bottom":
			if is_instance_valid(bottom_path):
				bottom_path.queue_free()

	match entry_direction_for_new_room_relative:
		"left":
			if new_room.has_node("Area2D_left"):
				new_room.get_node("Area2D_left").queue_free()
		"right":
			if new_room.has_node("Area2D_right"):
				new_room.get_node("Area2D_right").queue_free()
		"top":
			if new_room.has_node("Area2D_top"):
				new_room.get_node("Area2D_top").queue_free()
		"bottom":
			if new_room.has_node("Area2D_bottom"):
				new_room.get_node("Area2D_bottom").queue_free()

	if packed.resource_path == final_room_path:
		match entry_direction_for_new_room_relative:
			"left":
				if new_room.has_node("Sprite2D_block_Left"):
					new_room.get_node("Sprite2D_block_Left").queue_free()
				if new_room.has_node("Sprite2D_block_Left/StaticBody2D/CollisionShape2D"):
					new_room.get_node("Sprite2D_block_Left/StaticBody2D/CollisionShape2D").queue_free()
			"right":
				if new_room.has_node("Sprite2D_block_Right"):
					new_room.get_node("Sprite2D_block_Right").queue_free()
				if new_room.has_node("Sprite2D_block_Right/StaticBody2D/CollisionShape2D"):
					new_room.get_node("Sprite2D_block_Right/StaticBody2D/CollisionShape2D").queue_free()
			"top":
				if new_room.has_node("Sprite2D_block_Top"):
					new_room.get_node("Sprite2D_block_Top").queue_free()
				if new_room.has_node("Sprite2D_block_Top/StaticBody2D/CollisionShape2D"):
					new_room.get_node("Sprite2D_block_Top/StaticBody2D/CollisionShape2D").queue_free()
			"bottom":
				if new_room.has_node("Sprite2D_block_Bottom"):
					new_room.get_node("Sprite2D_block_Bottom").queue_free()
				if new_room.has_node("Sprite2D_block_Bottom/StaticBody2D/CollisionShape2D"):
					new_room.get_node("Sprite2D_block_Bottom/StaticBody2D/CollisionShape2D").queue_free()

	if new_room.has_method("configure_exits"):
		new_room.configure_exits(entry_direction_for_new_room_relative)


func enable_blockade(direction: String) -> void:
	match direction:
		"left":
			if is_instance_valid(blockade_left):
				blockade_left.visible = true
				collision_left.set_deferred("disabled", false)
		"right":
			if is_instance_valid(blockade_right):
				blockade_right.visible = true
				collision_right.set_deferred("disabled", false)
		"bottom":
			if is_instance_valid(blockade_bottom):
				blockade_bottom.visible = true
				collision_bottom.set_deferred("disabled", false)
		"top":
			if is_instance_valid(blockade_top):
				blockade_top.visible = true
				collision_top.set_deferred("disabled", false)

func free_blockade(direction: String) -> void:
	match direction:
		"left":
			if is_instance_valid(blockade_left):
				blockade_left.queue_free()
		"right":
			if is_instance_valid(blockade_right):
				blockade_right.queue_free()
		"bottom":
			if is_instance_valid(blockade_bottom):
				blockade_bottom.queue_free()
		"top":
			if is_instance_valid(blockade_top):
				blockade_top.queue_free()

func _on_enemy_entered(body: Node) -> void:
	if not body.is_in_group("enemy"):
		return
	has_detected_enemy_once = true
	enemies_in_area_count += 1
	enable_blockade("left")
	enable_blockade("right")
	enable_blockade("bottom")
	enable_blockade("top")

func _on_enemy_exited(body: Node) -> void:
	if not body.is_in_group("enemy"):
		return
	enemies_in_area_count = max(0, enemies_in_area_count - 1)
	if enemies_in_area_count == 0 and has_detected_enemy_once:
		defeated_rooms_count += 1
		for dir in ["left", "right", "bottom", "top"]:
			if dir == opened_exit_direction:
				continue
			if dir == "top" and not spawned_from_bottom:
				continue
			match dir:
				"left":
					blockade_left.visible = false
					collision_left.set_deferred("disabled", true)
				"right":
					blockade_right.visible = false
					collision_right.set_deferred("disabled", true)
				"bottom":
					blockade_bottom.visible = false
					collision_bottom.set_deferred("disabled", true)
				"top":
					blockade_top.visible = false
					collision_top.set_deferred("disabled", true)
