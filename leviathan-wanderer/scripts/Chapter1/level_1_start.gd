# level_1_start.gd
extends Node2D

@onready var left_path: Area2D = $Area2D_left
@onready var right_path: Area2D = $Area2D_right
@onready var bottom_path: Area2D = $Area2D_bottom

var offset_left: float = -3060.0
var offset_right: float = 3060.0
var offset_bottom: float = 1870.0

var roomA: PackedScene = preload("res://scene/Chapter1/Level1_roomA.tscn")
var roomB: PackedScene = preload("res://scene/Chapter1/Level1_roomB.tscn")
var roomC: PackedScene = preload("res://scene/Chapter1/Level1_roomC.tscn")

func _ready() -> void:
	randomize()
	left_path.connect("body_entered", Callable(self, "_spawn_room").bind("left"))
	right_path.connect("body_entered", Callable(self, "_spawn_room").bind("right"))
	bottom_path.connect("body_entered", Callable(self, "_spawn_room").bind("bottom"))

func _spawn_room(body: Node, direction: String) -> void:
	if not body.is_in_group("player"):
		return
	if left_path != null and is_instance_valid(left_path) and left_path.get_instance_id() == body.get_parent().get_instance_id():
		return
	if right_path != null and is_instance_valid(right_path) and right_path.get_instance_id() == body.get_parent().get_instance_id():
		return
	if bottom_path != null and is_instance_valid(bottom_path) and bottom_path.get_instance_id() == body.get_parent().get_instance_id():
		return

	var rooms: Array = [roomA, roomB, roomC]
	var packed: PackedScene = rooms[randi() % rooms.size()]
	call_deferred("_do_spawn", packed, direction)

func _do_spawn(packed: PackedScene, direction: String) -> void:
	var new_room: Node2D = packed.instantiate()
	add_child(new_room)
	match direction:
		"left":
			new_room.position = Vector2(offset_left, 0)
			if is_instance_valid(left_path):
				left_path.queue_free()
		"right":
			new_room.position = Vector2(offset_right, 0)
			if is_instance_valid(right_path):
				right_path.queue_free()
		"bottom":
			new_room.position = Vector2(0, offset_bottom)
			if is_instance_valid(bottom_path):
				bottom_path.queue_free()
	if new_room.has_method("configure_exits"):
		new_room.configure_exits(direction)
	else:
		print("Error: Newly spawned room does not have a 'configure_exits' method!")
