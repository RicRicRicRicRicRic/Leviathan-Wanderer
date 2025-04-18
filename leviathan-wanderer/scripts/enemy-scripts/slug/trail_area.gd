#trail_area.gd
#script of trailarea node in slug.tscn
extends Area2D

@export var disperse_speed: float = 250.0
@export var return_speed: float = 150.0

const CP_DEFAULT: float = -144.762
const CP1_MAX: float = 13.714
const CP2_MAX: float = 189.714
const CP3_MAX: float = 365.714

@onready var cp1: CollisionPolygon2D = $CollisionPolygon2D_1
@onready var cp2: CollisionPolygon2D = $CollisionPolygon2D_2
@onready var cp3: CollisionPolygon2D = $CollisionPolygon2D_3

var last_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	last_position = global_position
	var slug: Node2D = get_parent().get_parent() as Node2D
	if slug.has_signal("flipped"):
		slug.connect("flipped", Callable(self, "_on_slug_flipped"))
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	var velocity: Vector2 = (global_position - last_position) / delta
	last_position = global_position
	var factor: float = abs(velocity.x) / 380.0
	factor = clamp(factor, 0.0, 1.0)

	var target1: float = lerp(CP_DEFAULT, CP1_MAX, factor)
	var target2: float = lerp(CP_DEFAULT, CP2_MAX, factor)
	var target3: float = lerp(CP_DEFAULT, CP3_MAX, factor)

	var spd: float
	if factor > 0.1:
		spd = disperse_speed
	else:
		spd = return_speed

	cp1.position.x = move_toward(cp1.position.x, target1, spd * delta)
	cp2.position.x = move_toward(cp2.position.x, target2, spd * delta)
	cp3.position.x = move_toward(cp3.position.x, target3, spd * delta)

func reset_polygons() -> void:
	cp1.position.x = CP_DEFAULT
	cp2.position.x = CP_DEFAULT
	cp3.position.x = CP_DEFAULT

func _on_slug_flipped() -> void:
	reset_polygons()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.apply_slow(0.35)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		body.reset_speed()
