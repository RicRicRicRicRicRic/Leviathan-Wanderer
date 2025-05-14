# camera_2D.gd
extends Camera2D

@export var smoothing_speed: float = 5.0

var target_position: Vector2 = global_position 

func _ready() -> void:
	add_to_group("main_camera")
func _physics_process(delta: float) -> void:

	if global_position != target_position:

		global_position = global_position.lerp(target_position, smoothing_speed * delta)

func set_target_position(new_pos: Vector2) -> void:
	target_position = new_pos
	print("Camera target position set to: ", target_position)
