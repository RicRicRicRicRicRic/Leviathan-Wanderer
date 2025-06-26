#boss_proj_urchin.gd
extends RigidBody2D

@export var speed: float = 1500.0
@export var damage_amount: int = 55
@export var max_contacts: int = 1

var contacts_made: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("enemy_proj")
	contact_monitor = true
	max_contacts_reported = max_contacts

	continuous_cd = RigidBody2D.CCDMode.CCD_MODE_CAST_RAY

func set_initial_direction(direction_vector: Vector2) -> void:
	linear_velocity = direction_vector.normalized() * speed

func _on_body_entered(body: Node) -> void:
	print("Projectile hit: ", body.name, " (Group: ", body.get_groups(), ")")

	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
			print("Damage dealt to player!")

	contacts_made += 1
	
	if contacts_made >= max_contacts:
		queue_free()
		print("Projectile queued for free.")
