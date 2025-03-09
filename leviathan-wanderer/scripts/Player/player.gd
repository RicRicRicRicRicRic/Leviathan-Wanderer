#player.gd
extends "res://scripts/Interpolation/Interpolate.gd"

@onready var visuals = $Node2D
@onready var main = visuals.get_node("CharacterSprite2D")
@onready var wep = visuals.get_node("WeaponSprite2D")
@onready var marker = visuals.get_node("WeaponSprite2D/Marker2D")

const SPEED = 500.0
const JUMP_VELOCITY = -600.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var projectile_scene: PackedScene = preload("res://scene/projectile.tscn")

# Shooting cooldown variables
var can_shoot: bool = true
const shoot_cooldown = 0.1

func _ready() -> void:
	interp_visuals = visuals

func _physics_tick(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()

	# --- Movement Setup ---
	if not is_on_floor():
		velocity.y += gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction = Input.get_axis("left", "right")
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# --- Animation ---
	if direction != 0:
		main.play("run")
	else:
		main.play("iddle")
	
	# --- Flip Visuals Based on Mouse Position ---
	if mouse_pos.x < global_position.x:
		visuals.scale.x = -1
	else:
		visuals.scale.x = 1

	# --- Weapon Aiming ---
	var local_mouse = visuals.to_local(mouse_pos)
	var aim_angle = local_mouse.angle()
	aim_angle = clamp(aim_angle, deg_to_rad(-50), deg_to_rad(50))
	wep.rotation = aim_angle

	# --- Shooting ---
	if Input.is_action_pressed("Shoot") and can_shoot:
		can_shoot = false
		Projectile.shoot(marker.global_position, mouse_pos, projectile_scene, self)
		await get_tree().create_timer(shoot_cooldown).timeout
		can_shoot = true
