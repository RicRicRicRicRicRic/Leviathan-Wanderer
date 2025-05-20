#Interpolate.gd
extends CharacterBody2D

@export var enable_interpolation: bool = true  
@export var interp_strength: float = 1.0  

var interp_visuals: Node2D = null
var previous_position: Vector2

func _ready() -> void:
	previous_position = global_position

func _process(_delta: float) -> void:
	if enable_interpolation and interp_visuals:
		var fraction = Engine.get_physics_interpolation_fraction() * interp_strength
		interp_visuals.global_position = previous_position.lerp(global_position, fraction)
