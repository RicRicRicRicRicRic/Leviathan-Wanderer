extends Area2D

const CAMERA_GROUP = "main_camera"
var main_camera: Camera2D = null
var tracked_player: Node = null

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)
	_find_camera()

func _process(_delta: float) -> void:
	if not main_camera:
		_find_camera()
	elif tracked_player and main_camera:
		main_camera.set_target_position(Vector2(tracked_player.global_position.x, main_camera.global_position.y))

func _find_camera() -> void:
	main_camera = get_tree().get_first_node_in_group(CAMERA_GROUP)
	if not main_camera:
		print("Error: Camera2D node not found! Make sure your Camera2D is in the '" + CAMERA_GROUP + "' group.")
	else:
		print("Camera2D found: ", main_camera.name)
		set_process(main_camera == null or tracked_player != null)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		tracked_player = body
		if main_camera:
			main_camera.set_target_position(Vector2(body.global_position.x, main_camera.global_position.y))
		else:
			print("Cannot set camera target: main_camera is null")
		set_process(main_camera == null or tracked_player != null)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		tracked_player = null
		set_process(main_camera == null)
