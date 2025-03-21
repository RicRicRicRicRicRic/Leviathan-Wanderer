extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$FPS_meter.text = "FPS: " + str(Engine.get_frames_per_second())

	var refresh_rate = DisplayServer.screen_get_refresh_rate()
	$HZ_meter.text = "Hz: " + str(refresh_rate)
