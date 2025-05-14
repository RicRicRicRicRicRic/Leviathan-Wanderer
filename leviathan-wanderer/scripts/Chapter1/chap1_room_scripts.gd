#chap1_room_scripts
extends Node2D

@onready var blockade_left:		Sprite2D = $Sprite2D_block_Left
@onready var blockade_right:	Sprite2D = $Sprite2D_block_Right
@onready var blockade_bottom:	Sprite2D = $Sprite2D_block_Bottom
@onready var blockade_top:		Sprite2D = $Sprite2D_block_Top

@onready var left_path: Area2D = $Area2D_left
@onready var right_path: Area2D = $Area2D_right
@onready var bottom_path: Area2D = $Area2D_bottom

func configure_exits(spawn_direction: String) -> void:
	print(self.name, ": Configuring exits (Blockades Only). Spawned from: ", spawn_direction)

	match spawn_direction:
		"left":
			if blockade_right != null:
				blockade_right.queue_free()
				right_path.queue_free()
				print("Removed blockade_right")
		"right":
			if blockade_left != null:
				blockade_left.queue_free()
				left_path.queue_free()
				print("Removed blockade_left")
		"bottom":
			if blockade_top != null:
				blockade_top.queue_free()
				print("Removed blockade_top (spawned from bottom)")
