#slug_trail.gd
#script of line2d in slug.tscn
extends Line2D

const MIN_TRAIL_LENGTH: float = 135.0
const MIN_DISTANCE_BETWEEN_POINTS: float = 1.0
const SHRINK_RATE_NORMAL: float = 100.0
const SHRINK_RATE_MAX: float = 125.0
const MAX_POINTS: int = 475

var time_accumulator: float = 0.0
var cached_total_length: float = 0.0

func _ready() -> void:
	clear_points()
	cached_total_length = 0.0
	var slug: Node2D = get_parent() as Node2D
	if slug:
		add_point(slug.global_position)

func _process(delta: float) -> void:
	var slug: Node2D = get_parent() as Node2D
	if not slug:
		return

	var current_pos: Vector2 = slug.global_position

	if points.size() > 0:
		var last_point: Vector2 = points[points.size() - 1]
		var dist: float = current_pos.distance_to(last_point)
		if dist > MIN_DISTANCE_BETWEEN_POINTS:
			add_point(current_pos)
			cached_total_length += dist
	else:
		add_point(current_pos)

	var shrink_rate: float = SHRINK_RATE_NORMAL
	if points.size() > MAX_POINTS:
		shrink_rate = SHRINK_RATE_MAX

	time_accumulator += delta
	var to_remove: int = int(shrink_rate * time_accumulator)
	if to_remove > 0:
		time_accumulator = 0.0
		var removed: int = 0
		while removed < to_remove and points.size() > 2 and cached_total_length > MIN_TRAIL_LENGTH:
			var seg: float = points[0].distance_to(points[1])
			cached_total_length -= seg
			remove_point(0)
			removed += 1

	while points.size() > MAX_POINTS:
		var seg: float = points[0].distance_to(points[1])
		cached_total_length -= seg
		remove_point(0)

func get_total_length() -> float:
	return cached_total_length
