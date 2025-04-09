#slime.gd
extends "res://scripts/Optimization/Interpolate.gd"

# Speed and gravity
const SPEED: float = 300.0
const GRAVITY: float = 980.0

# Nodes
@onready var visuals: Node2D = $Node2D
@onready var slime_main: AnimatedSprite2D = visuals.get_node("AnimatedSprite2D") as AnimatedSprite2D
@onready var raycast_wall: RayCast2D = visuals.get_node("RayCast2D_wall") as RayCast2D
@onready var raycast_fall: RayCast2D = visuals.get_node("RayCast2D_height") as RayCast2D
@onready var head_collision: CollisionShape2D = $CollisionShape2D_head
@onready var body_collision: CollisionShape2D = $CollisionShape2D_body

# Variables to store the original (left-facing) properties
var head_original_x: float
var head_original_rot_deg: float
var body_original_x: float

# Movement variables
var direction: int = -1
var was_colliding: bool = false

func _ready() -> void:
	interp_visuals = visuals
	previous_position = global_position
	raycast_wall.enabled = true
	raycast_fall.enabled = true
	
	# Capture the original positions and rotation in degrees from the collision shapes
	head_original_x = head_collision.position.x
	head_original_rot_deg = rad_to_deg(head_collision.rotation)
	body_original_x = body_collision.position.x

func update_collision_shapes() -> void:
	if direction == 1:
		# For right-facing, mirror the original left values.
		head_collision.position.x = -head_original_x
		head_collision.rotation = deg_to_rad(180 - head_original_rot_deg)
		body_collision.position.x = -body_original_x
	else:
		# For left-facing, use the original values.
		head_collision.position.x = head_original_x
		head_collision.rotation = deg_to_rad(head_original_rot_deg)
		body_collision.position.x = body_original_x

func _physics_process(delta: float) -> void:
	previous_position = global_position

	# Apply gravity if not on the floor
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	
	# Reverse direction when a new wall collision is detected
	var is_colliding: bool = raycast_wall.is_colliding()
	if is_colliding and not was_colliding:
		direction *= -1
	was_colliding = is_colliding

	# Flip the visuals based on current direction
	visuals.scale.x = 1.0 if direction == -1 else -1.0

	# Set horizontal velocity
	velocity.x = SPEED * direction
	
	# Move the slime and slide along surfaces
	move_and_slide()
	
	# Update collision shapes to reflect the current direction
	update_collision_shapes()
