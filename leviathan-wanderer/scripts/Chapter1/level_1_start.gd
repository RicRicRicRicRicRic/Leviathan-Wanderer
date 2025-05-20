# level_1_start.gd
extends Node2D

@onready var left_path: Area2D = $Area2D_left
@onready var right_path: Area2D = $Area2D_right
@onready var bottom_path: Area2D = $Area2D_bottom

@onready var blockade_left: Sprite2D = $Sprite2D_block_Left
@onready var blockade_right: Sprite2D = $Sprite2D_block_Right
@onready var blockade_bottom: Sprite2D = $Sprite2D_block_Bottom

@onready var collision_left: CollisionShape2D = $Sprite2D_block_Left/StaticBody2D/CollisionShape2D
@onready var collision_right: CollisionShape2D = $Sprite2D_block_Right/StaticBody2D/CollisionShape2D
@onready var collision_bottom: CollisionShape2D = $Sprite2D_block_Bottom/StaticBody2D/CollisionShape2D

var offset_left: float = -3060.0
var offset_right: float = 3060.0
var offset_bottom: float = 1870.0

var roomA: PackedScene = preload("res://scene/Chapter1/Level1_roomA.tscn")
var roomB: PackedScene = preload("res://scene/Chapter1/Level1_roomB.tscn")
var roomC: PackedScene = preload("res://scene/Chapter1/Level1_roomC.tscn")
var roomD: PackedScene = preload("res://scene/Chapter1/Level1_roomD.tscn")

var room_spawned: bool = false

func _ready() -> void:
	randomize()
	disable_all_blockades()
	left_path.connect("body_entered", Callable(self, "_on_path_entered").bind("left"))
	right_path.connect("body_entered", Callable(self, "_on_path_entered").bind("right"))
	bottom_path.connect("body_entered", Callable(self, "_on_path_entered").bind("bottom"))

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

func _on_path_entered(body: Node, direction: String) -> void:
	if not body.is_in_group("player"):
		return
	if room_spawned:
		return
	room_spawned = true
	call_deferred("handle_blockades", direction)
	var rooms: Array = [roomA, roomB, roomC, roomD]
	var packed: PackedScene = rooms[randi() % rooms.size()]
	call_deferred("_do_spawn", packed, direction)

func handle_blockades(direction: String) -> void:
	if direction == "left":
		enable_blockade("right")
		enable_blockade("bottom")
		free_blockade("left")
	elif direction == "right":
		enable_blockade("left")
		enable_blockade("bottom")
		free_blockade("right")
	elif direction == "bottom":
		enable_blockade("left")
		enable_blockade("right")
		free_blockade("bottom")

func enable_blockade(direction: String) -> void:
	match direction:
		"left":
			if is_instance_valid(blockade_left):
				blockade_left.visible = true
			if is_instance_valid(collision_left):
				collision_left.set_deferred("disabled", false)
		"right":
			if is_instance_valid(blockade_right):
				blockade_right.visible = true
			if is_instance_valid(collision_right):
				collision_right.set_deferred("disabled", false)
		"bottom":
			if is_instance_valid(blockade_bottom):
				blockade_bottom.visible = true
			if is_instance_valid(collision_bottom):
				collision_bottom.set_deferred("disabled", false)

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

func _do_spawn(packed: PackedScene, direction: String) -> void:
	var new_room: Node2D = packed.instantiate()
	add_child(new_room)
	match direction:
		"left":
			new_room.position = Vector2(offset_left, 0)
		"right":
			new_room.position = Vector2(offset_right, 0)
		"bottom":
			new_room.position = Vector2(0, offset_bottom)
	match direction:
		"left":
			if is_instance_valid(left_path):
				left_path.queue_free()
		"right":
			if is_instance_valid(right_path):
				right_path.queue_free()
		"bottom":
			if is_instance_valid(bottom_path):
				bottom_path.queue_free()
	if new_room.has_method("configure_exits"):
		new_room.configure_exits(direction)
	match direction:
		"left":
			if new_room.has_node("Area2D_right"):
				new_room.get_node("Area2D_right").queue_free()
		"right":
			if new_room.has_node("Area2D_left"):
				new_room.get_node("Area2D_left").queue_free()
