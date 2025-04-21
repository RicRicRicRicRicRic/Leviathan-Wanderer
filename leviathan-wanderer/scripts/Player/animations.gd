# animations.gd
# Attach this to your CharacterSprite2D node
extends AnimatedSprite2D

var time_to_apex: float
var jump_hang_duration: float
var time_to_fall: float

func play_animation_on_floor(direction: float) -> void:
	if direction != 0.0:
		play("run")
	else:
		play("iddle")
	speed_scale = 1.0

func play_animation_in_air(is_hanging: bool, velocity_y: float) -> void:
	if is_hanging:
		play("jump_acce")
		_adjust_animation_speed("jump_acce", jump_hang_duration)
	elif velocity_y < 100.0:
		play("jump_hang")
		_adjust_animation_speed("jump_hang", time_to_apex)
	else:
		play("jump_decce")
		_adjust_animation_speed("jump_decce", time_to_fall)
		
func _adjust_animation_speed(anim_name: String, duration: float) -> void:
	var frame_count: int = sprite_frames.get_frame_count(anim_name)
	var fps: float = sprite_frames.get_animation_speed(anim_name)
	var anim_duration: float = float(frame_count) / fps
	if anim_duration > 0.0 and duration > 0.0:
		speed_scale = anim_duration / duration
	else:
		speed_scale = 1.0
