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

func _ready() -> void:
	var slug: Node2D = get_parent().get_parent() as Node2D
	if slug.has_signal("flipped"):
		slug.connect("flipped", Callable(self, "_on_slug_flipped"))
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	var slug = get_parent().get_parent()
	var is_moving = abs(slug.velocity.x) > 0.0
	var target1: float
	var target2: float
	var target3: float
	var spd: float
	if is_moving:
		target1 = CP1_MAX
		target2 = CP2_MAX
		target3 = CP3_MAX
		spd = disperse_speed
	else:
		target1 = CP_DEFAULT
		target2 = CP_DEFAULT
		target3 = CP_DEFAULT
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
		body.apply_slow(0.25)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		body.reset_speed()
