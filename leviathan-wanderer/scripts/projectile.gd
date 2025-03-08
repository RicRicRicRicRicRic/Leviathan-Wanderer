#projectile.gd
extends CharacterBody2D  # Inherit from CharacterBody2D
class_name Projectile    # Register this class as "Projectile"

@export var SPEED = 700                # Projectile speed (modifiable in editor)
@export var fire_rate: float = 0.3     # Cooldown time between shots (seconds)
var dir: float = 0.0                   # Direction of travel (in radians)
var spawnPos: Vector2                  # Global spawn position
var spawnRot: float                    # Initial rotation (in radians)
static var _can_shoot = true           # Static flag to control fire rate cooldown

static func shoot(start_pos: Vector2, target: Vector2, projectile_scene: PackedScene, shooter: Node) -> void:
	# Fire rate check and cooldown
	if not _can_shoot: 
		return                    # Exit if still cooling down
	_can_shoot = false            # Begin cooldown

	# Projectile instantiation and setup
	var proj = projectile_scene.instantiate()  # Instance the projectile scene
	proj.spawnPos = start_pos                    # Set projectile's spawn position
	var angle = (target - start_pos).normalized().angle()
	proj.dir = angle                             # Set travel direction
	proj.spawnRot = angle                        # Set spawn rotation
	proj.rotation = angle                        # Set current rotation

	# Adjust sprite based on target position
	if target.x < start_pos.x and proj.has_node("AnimatedSprite2D"):
		proj.get_node("AnimatedSprite2D").flip_v = true  # Flip sprite if target is to the left

	# Collision and scene management
	proj.add_collision_exception_with(shooter)            # Prevent collision with shooter
	shooter.get_tree().current_scene.add_child(proj)        # Add projectile to the current scene

	# Timer setup for fire rate cooldown reset
	var timer = Timer.new()              # Create a new Timer node
	timer.wait_time = proj.fire_rate     # Set wait time using projectile's fire_rate
	timer.one_shot = true                # Timer will run only once
	timer.autostart = true               # Timer starts automatically
	timer.connect("timeout", Callable(Projectile, "_reset_fire_rate"))  # Connect timeout signal to reset function
	shooter.get_tree().current_scene.add_child(timer)       # Add the timer to the scene


static func _reset_fire_rate() -> void: _can_shoot = true  # Reset the shooting cooldown

func _ready() -> void:
	# Initialize position, rotation, and group membership
	global_position = spawnPos; global_rotation = spawnRot; add_to_group("projectiles") 
	for p in get_tree().get_nodes_in_group("projectiles"):
		# Exclude collision with other projectiles
		if p != self: add_collision_exception_with(p)  

func _physics_process(_delta: float) -> void:
	# Update velocity and move the projectile
	velocity = Vector2(SPEED, 0).rotated(dir); move_and_slide()  
	for i in range(get_slide_collision_count()):
		# Remove projectile upon collision
		if get_slide_collision(i): queue_free(); break  
