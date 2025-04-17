#slug_trail.gd
#script of line2d in slug.tscn
extends Line2D

const MIN_TRAIL_LENGTH: float = 135.0
const MIN_DISTANCE_BETWEEN_POINTS: float = 1.0
const SHRINK_RATE_NORMAL: float = 100
const SHRINK_RATE_MAX: float = 125
const MAX_POINTS: float = 475

var time_accumulator: float = 0.0
var cached_total_length: float = 0.0

func _ready() -> void:
	clear_points()
	cached_total_length = 0.0

func _process(delta: float) -> void:
	var trail_area: Node2D = get_parent() as Node2D
	if trail_area == null:
		return

	var current_pos: Vector2 = trail_area.global_position

	if points.size() > 0:
		var last_point: Vector2 = points[points.size() - 1]
		var distance: float = current_pos.distance_to(last_point)
		if distance > MIN_DISTANCE_BETWEEN_POINTS:
			add_point(current_pos)
			cached_total_length += distance
	else:
		add_point(current_pos)

	var shrink_rate: float = SHRINK_RATE_MAX if points.size() > MAX_POINTS else SHRINK_RATE_NORMAL
	time_accumulator += delta
	var points_to_remove: int = int(shrink_rate * time_accumulator)

	if points_to_remove > 0:
		time_accumulator = 0.0

		var removed_count: int = 0
		while removed_count < points_to_remove and points.size() > 2 and cached_total_length > MIN_TRAIL_LENGTH:
			if points.size() >= 2:
				cached_total_length -= points[0].distance_to(points[1])
				remove_point(0)
				removed_count += 1
			else:
				break

	while points.size() > MAX_POINTS:
		if points.size() >= 2:
			cached_total_length -= points[0].distance_to(points[1])
		remove_point(0)

func get_total_length() -> float:
	return cached_total_length
