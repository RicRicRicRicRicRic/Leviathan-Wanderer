# isopod_curled.gd
extends RigidBody2D

static var SPEED: float = 1500.0
@export var knockback_strength: float = 1800.0

var _player_node: Node = null
@onready var timer_whilecurl: Timer = $Timer_whilecurl
@onready var damage_area: Area2D = $Area2D
@onready var isopod_anim: AnimatedSprite2D = $AnimatedSprite2D

var is_uncurling: bool = false

func _ready() -> void:
	_player_node = get_tree().get_nodes_in_group("player")[0]
	add_to_group("isopod_curled")
	launch_towards_player()
	timer_whilecurl.start()
	timer_whilecurl.timeout.connect(_on_Timer_whilecurl_timeout)
	damage_area.body_entered.connect(_on_body_entered)
	isopod_anim.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta: float) -> void:
	if is_uncurling:
		return

func launch_towards_player() -> void:
	if _player_node:
		var direction = (_player_node.global_position - global_position).normalized()
		linear_velocity = direction * SPEED

func _on_animation_finished() -> void:
	if is_uncurling and isopod_anim.animation == "uncurl":
		queue_free()

func _on_body_entered(body: Node) -> void:
	if linear_velocity.length() > 150:
		if body.is_in_group("player") and body.has_method("take_damage"):
			_player_node = body
			body.take_damage(95)
			var diff: Vector2 = body.global_position - global_position
			var knock_dir: Vector2 = Vector2.ZERO
			if diff.length() > 0.0:
				knock_dir = diff.normalized()
			var knockback_force: Vector2 = knock_dir * knockback_strength
			body.knockback(knockback_force)

func _on_Timer_whilecurl_timeout() -> void:
	is_uncurling = true
	linear_velocity = Vector2.ZERO
	isopod_anim.play("uncurl")
