#slug_trail.gd
#script of line2d in slug.tscn
extends Line2D

const MIN_TRAIL_LENGTH = 135.0
const MIN_DISTANCE_BETWEEN_POINTS = 1.0
const SHRINK_RATE_NORMAL = 100
const SHRINK_RATE_MAX = 125    
const MAX_POINTS = 500         

var time_accumulator := 0.0

func _ready() -> void:
	clear_points()

func _process(delta: float) -> void:
	var trail_area := get_parent()
	if not trail_area:
		return

	var current_pos = trail_area.global_position
	var last_point: Vector2 = points[points.size() - 1] if points.size() > 0 else Vector2.INF

	if current_pos.distance_to(last_point) > MIN_DISTANCE_BETWEEN_POINTS:
		add_point(current_pos)
	var shrink_rate = SHRINK_RATE_NORMAL
	if points.size() > MAX_POINTS:
		shrink_rate = SHRINK_RATE_MAX
	time_accumulator += delta
	var points_to_remove = int(shrink_rate * time_accumulator)
	for i in range(points_to_remove):
		if points.size() > 2 and get_total_length() > MIN_TRAIL_LENGTH:
			remove_point(0)
		else:
			break
	if points_to_remove > 0:
		time_accumulator = 0.0
	while points.size() > MAX_POINTS:
		remove_point(0)

func get_total_length() -> float:
	var length := 0.0
	for i in range(1, points.size()):
		length += points[i - 1].distance_to(points[i])
	return length
