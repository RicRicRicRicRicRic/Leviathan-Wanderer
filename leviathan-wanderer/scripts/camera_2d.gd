extends Camera2D


@export var smoothing: float = 0.5

func _ready() -> void:
	set_process(false)
	set_physics_process(true)
	
func _physics_process(delta: float) -> void:
	offset = offset.lerp(Vector2.ZERO, smoothing)
