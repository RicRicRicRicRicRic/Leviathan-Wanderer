# beetle_spray.gd
extends Area2D

signal spray_finished_expanding 

@onready var collision_polygon_2d: CollisionPolygon2D = $CollisionPolygon2D
@onready var timer: Timer = $PoisonTimer
@onready var particles: GPUParticles2D = $GPUParticles2D

@export var scale_speed: float = 0.85
@export var debuff_damage_interval: float = 0.35
@export var debuff_damage_amount: int = 15

var initial_scale: Vector2
var _debuffed_players: Dictionary = {}

func _ready():
	body_entered.connect(_on_body_entered)
	timer.timeout.connect(_on_timer_timeout)
	initial_scale = collision_polygon_2d.scale
	collision_polygon_2d.scale = Vector2(0.1, 0.1)
	particles.emitting = true
	var tween: Tween = create_tween()
	tween.tween_property(collision_polygon_2d, "scale", initial_scale, scale_speed)
	tween.tween_callback(collision_polygon_2d.queue_free)
	tween.tween_callback(timer.start)
	tween.tween_callback(self._on_scale_tween_completed) 

func _physics_process(delta: float) -> void:
	var players_to_remove: Array[Node2D] = []

	for player_node in _debuffed_players.keys():
		var debuff_data = _debuffed_players[player_node]

		debuff_data["time_remaining"] -= delta
		debuff_data["time_since_last_tick"] += delta
		if debuff_data["time_since_last_tick"] >= debuff_damage_interval:
			if is_instance_valid(player_node) and player_node.has_method("take_damage"):
				player_node.take_damage(debuff_damage_amount)
			debuff_data["time_since_last_tick"] = 0.0

		if debuff_data["time_remaining"] <= 0.0 or not is_instance_valid(player_node):
			players_to_remove.append(player_node)
		else:
			_debuffed_players[player_node] = debuff_data

	for player_node in players_to_remove:
		_debuffed_players.erase(player_node)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		self.set_deferred("monitoring", false)
		if not _debuffed_players.has(body):
			_debuffed_players[body] = {
				"time_remaining": timer.wait_time,
				"time_since_last_tick": 0.0
			}

func _on_timer_timeout() -> void:
	_debuffed_players.clear()
	queue_free()

func _on_scale_tween_completed() -> void:
	emit_signal("spray_finished_expanding")
