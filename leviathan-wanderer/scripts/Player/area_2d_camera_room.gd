#area_2d_camera_room.gd
extends Node2D

@onready var area2D: Area2D = $Area2D

const CAMERA_GROUP = "main_camera" 
var main_camera: Camera2D = null

func _ready() -> void:
	area2D.body_entered.connect(_on_body_entered)
	main_camera = get_tree().get_first_node_in_group(CAMERA_GROUP)
	if not main_camera:
		print("Error: Camera2D node not found! Make sure your Camera2D is in the '" + CAMERA_GROUP + "' group.")


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if main_camera:
			main_camera.set_target_position(global_position) 
