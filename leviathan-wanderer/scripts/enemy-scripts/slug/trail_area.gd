#trail_area.gd
#script of trailarea node in slug.tscn
extends Area2D

@export var disperse_speed: float = 200.0 
@export var return_speed: float = 125.0     
@export var flip_return_multiplier: float = 1000  
@export var flip_duration: float = 1           

const CP_DEFAULT: float = -114.286
const CP1_MAX: float = -15.238
const CP2_MAX: float = 121.905
const CP3_MAX: float = 259.048

@onready var cp1: CollisionPolygon2D = $CollisionPolygon2D_1
@onready var cp2: CollisionPolygon2D = $CollisionPolygon2D_2
@onready var cp3: CollisionPolygon2D = $CollisionPolygon2D_3

var last_position: Vector2
var last_visual_scale_x: float
var flip_timer: float = 0.0

func _ready() -> void:
	last_position = global_position
	last_visual_scale_x = get_parent().scale.x
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if flip_timer > 0:
		flip_timer = max(0, flip_timer - delta)
	var current_velocity: Vector2 = (global_position - last_position) / delta
	last_position = global_position

	var factor: float = clamp(abs(current_velocity.x) / 380.0, 0, 1)
	
	var target_cp1: float = lerp(CP_DEFAULT, CP1_MAX, factor)
	var target_cp2: float = lerp(CP_DEFAULT, CP2_MAX, factor)
	var target_cp3: float = lerp(CP_DEFAULT, CP3_MAX, factor)

	var current_visual_scale_x: float = get_parent().scale.x
	if current_visual_scale_x != last_visual_scale_x:
		flip_timer = flip_duration   
	last_visual_scale_x = current_visual_scale_x
	var speed: float
	if factor > 0.1:
		speed = disperse_speed
	else:
		if flip_timer > 0:
			speed = return_speed * flip_return_multiplier
		else:
			speed = return_speed
	cp1.position.x = move_toward(cp1.position.x, target_cp1, speed * delta)
	cp2.position.x = move_toward(cp2.position.x, target_cp2, speed * delta)
	cp3.position.x = move_toward(cp3.position.x, target_cp3, speed * delta)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.apply_slow(0.5)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		body.reset_speed()
