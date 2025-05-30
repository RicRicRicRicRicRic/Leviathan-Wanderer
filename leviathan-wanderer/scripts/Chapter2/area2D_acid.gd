# area2D_acid.gd
extends Area2D

@onready var collision: CollisionPolygon2D = $CollisionPolygon2D

var players_in_acid: Array[Node2D] = []
const DAMAGE_AMOUNT: int = 15
const DAMAGE_INTERVAL: float = 0.1

var _time_since_last_damage_tick: float = 0.0
var _is_damage_active: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if _is_damage_active:
		_time_since_last_damage_tick += delta

		if _time_since_last_damage_tick >= DAMAGE_INTERVAL:
			_apply_damage_tick()
			_time_since_last_damage_tick = 0.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not players_in_acid.has(body):
			players_in_acid.append(body)

		if players_in_acid.size() == 1:
			_is_damage_active = true
			_time_since_last_damage_tick = 0.0

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if players_in_acid.has(body):
			players_in_acid.erase(body)

		if players_in_acid.is_empty():
			_is_damage_active = false
			_time_since_last_damage_tick = 0.0

func _apply_damage_tick() -> void:
	var players_to_remove: Array[Node2D] = []

	for player_node in players_in_acid:
		if is_instance_valid(player_node) and player_node.has_method("take_damage"):
			player_node.take_damage(DAMAGE_AMOUNT)
		else:
			players_to_remove.append(player_node)

	for player_node in players_to_remove:
		players_in_acid.erase(player_node)

	if players_in_acid.is_empty():
		_is_damage_active = false
		_time_since_last_damage_tick = 0.0
