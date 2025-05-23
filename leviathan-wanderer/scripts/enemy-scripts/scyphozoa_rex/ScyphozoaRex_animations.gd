# ScyphozoaRex_animations.gd
#script attached to Node2D_visuals of boss
extends Node2D

@onready var tentacle_left: Sprite2D = $Sprite2D_tentacle_left
@onready var tentacle_right: Sprite2D = $Sprite2D_tentacle_right
@onready var tentacle_lines: Node2D = $Node2D_Lines_tentacles
@onready var eye_pupil: Sprite2D = $Sprite2D_pupil
@onready var left_side_tentacles: Node2D = $Node2D_Lines_tentacles/Node2D_left_side
@onready var right_side_tentacles: Node2D = $Node2D_Lines_tentacles/Node2D_right_side

@export_range(0.1, 5.0, 0.1) var rotation_speed: float = 0.75
@export_range(5.0, 45.0, 1.0) var max_rotation_degrees: float = 10.0
@export_range(1.0, 100.0, 1.0) var marker_move_amplitude: float = 65.0
@export_range(0.1, 5.0, 0.1) var marker_move_speed: float = 0.75
@export_range(2, 20, 1) var line_segments: int = 10
@export_range(0.0, 20.0, 0.1) var line_sway_strength: float = 10.0
@export_range(0.1, 5.0, 0.1) var line_sway_frequency: float = 2.0

@export_range(0.1, 20.0, 0.1) var pupil_rotation_speed: float = 5.0
@export_range(-PI, PI, 0.01) var pupil_base_rotation_offset: float = -PI / 2.0 

var _time_elapsed: float = 0.0
var _tentacle_data: Array = []

func _ready() -> void:
	tentacle_left.rotation_degrees = 0
	tentacle_right.rotation_degrees = 0
	position = Vector2.ZERO
	randomize()

	var add_tentacle_group = func(parent_node: Node2D, initial_sway_direction: float):
		if parent_node:
			for child in parent_node.get_children():
				if child is Node2D:
					var line_node = child.get_node("Line2D") as Line2D
					var outline_line_node = child.get_node("Line2D_outline") as Line2D
					var start_marker = child.get_node("Marker2D_start") as Marker2D
					var end_marker = child.get_node("Marker2D_end") as Marker2D
					if line_node and outline_line_node and start_marker and end_marker:
						var base_end_x = end_marker.position.x
						var sway_phase_offset = randf() * TAU
						var marker_speed_multiplier = randf_range(0.8, 1.2)
						var sway_frequency_multiplier = randf_range(0.8, 1.2)
						_tentacle_data.append({
							"line": line_node,
							"outline_line": outline_line_node,
							"start_marker": start_marker,
							"end_marker": end_marker,
							"base_end_x": base_end_x,
							"sway_phase_offset": sway_phase_offset,
							"marker_speed_multiplier": marker_speed_multiplier,
							"sway_frequency_multiplier": sway_frequency_multiplier,
							"initial_sway_direction": initial_sway_direction
						})

	add_tentacle_group.call(left_side_tentacles, 1.0)
	add_tentacle_group.call(right_side_tentacles, -1.0)

func _update_single_tentacle(tentacle_info: Dictionary, current_time: float) -> void:
	var line_node: Line2D = tentacle_info.line
	var outline_line_node: Line2D = tentacle_info.outline_line
	var start_marker: Marker2D = tentacle_info.start_marker
	var end_marker: Marker2D = tentacle_info.end_marker
	var base_end_x: float = tentacle_info.base_end_x
	var sway_phase_offset: float = tentacle_info.sway_phase_offset
	var marker_speed_multiplier: float = tentacle_info.marker_speed_multiplier
	var sway_frequency_multiplier: float = tentacle_info.sway_frequency_multiplier
	var initial_sway_direction: float = tentacle_info.initial_sway_direction

	var marker_x_offset = sin(current_time * marker_move_speed * marker_speed_multiplier + sway_phase_offset) * marker_move_amplitude * initial_sway_direction
	end_marker.position.x = base_end_x + marker_x_offset

	line_node.clear_points()
	outline_line_node.clear_points()

	var start_pos = start_marker.global_position
	var end_pos = end_marker.global_position
	var direction = (end_pos - start_pos).normalized()
	var perpendicular_direction = Vector2(-direction.y, direction.x)

	for i in range(line_segments + 1):
		var t = float(i) / line_segments
		var point_on_line = start_pos.lerp(end_pos, t)
		var sway_factor = sin(t * PI)
		var sway_offset = sin(current_time * line_sway_frequency * sway_frequency_multiplier + t * PI + sway_phase_offset) * line_sway_strength * sway_factor * initial_sway_direction
		var swayed_point = point_on_line + perpendicular_direction * sway_offset
		var local_swayed_point = line_node.to_local(swayed_point)
		line_node.add_point(local_swayed_point)
		outline_line_node.add_point(local_swayed_point)

func _physics_process(delta: float) -> void:
	_time_elapsed += delta * rotation_speed
	var current_swing_factor = cos(_time_elapsed)
	var rotation_angle_degrees = current_swing_factor * max_rotation_degrees
	tentacle_left.rotation_degrees = rotation_angle_degrees
	tentacle_right.rotation_degrees = -rotation_angle_degrees

	for tentacle_info in _tentacle_data:
		_update_single_tentacle(tentacle_info, _time_elapsed)

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player_node = players[0]
		var player_global_pos = player_node.global_position
		var pupil_global_pos = eye_pupil.global_position

		var direction_to_player = player_global_pos - pupil_global_pos
		var target_rotation = direction_to_player.angle() + pupil_base_rotation_offset

		eye_pupil.rotation = lerp_angle(eye_pupil.rotation, target_rotation, delta * pupil_rotation_speed)
