extends Node2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var tp_distance = $AnimatedSprite2D/Marker2D
@onready var line_tp_ready = $Line2D_tp_ready
@onready var line_tp_cd = $Line2D2_tp_cd
@onready var line_tp_wall = $Line2D2_tp_wall

var _player_ref: CharacterBody2D = null
var _player_teleport_cooldown_ref: Timer = null
var _player_max_teleport_range: float = 1000.0
var target_position: Vector2 = Vector2.ZERO
var lerp_speed: float = 20.0
var teleport_mana_cost: int = 100

func _ready() -> void:
	add_to_group("teleport")

func set_teleport_data(player_node: CharacterBody2D, cooldown_timer: Timer) -> void:
	_player_ref = player_node
	_player_teleport_cooldown_ref = cooldown_timer
	global_position = _player_ref.global_position
	target_position = _player_ref.global_position

func _process(delta: float) -> void:
	if _player_ref and _player_teleport_cooldown_ref:
		global_position = global_position.lerp(target_position, lerp_speed * delta)

		var has_enough_mana: bool = false
		if _player_ref.has_method("get_current_mana"): 
			has_enough_mana = _player_ref.get_current_mana() >= teleport_mana_cost
		elif _player_ref.has_node("current_mana"): 
			has_enough_mana = _player_ref.current_mana.value >= teleport_mana_cost
		elif _player_ref.has_method("get") and _player_ref.get("current_mana") != null:
			has_enough_mana = _player_ref.current_mana >= teleport_mana_cost
		else:
			has_enough_mana = _player_ref.current_mana >= teleport_mana_cost


		var is_cooldown_stopped = _player_teleport_cooldown_ref.is_stopped()
		var is_current_position_clear = not _is_current_target_colliding()

		if not is_current_position_clear:
			animated_sprite.play("teleport_on_wall")
			line_tp_ready.visible = false
			line_tp_cd.visible = false
			line_tp_wall.visible = true
		elif not is_cooldown_stopped or not has_enough_mana:
			animated_sprite.play("teleport_on_cd")
			line_tp_ready.visible = false
			line_tp_cd.visible = true
			line_tp_wall.visible = false
		else:
			animated_sprite.play("teleport_ready")
			line_tp_ready.visible = true
			line_tp_cd.visible = false
			line_tp_wall.visible = false

		animated_sprite.flip_h = global_position.x < _player_ref.global_position.x
		var player_global_pos = _player_ref.global_position
		var player_local_pos = to_local(player_global_pos)
		line_tp_ready.points = [player_local_pos, Vector2.ZERO]
		line_tp_cd.points = [player_local_pos, Vector2.ZERO]
		line_tp_wall.points = [player_local_pos, Vector2.ZERO]

func update_position(mouse_pos: Vector2) -> void:
	if _player_ref:
		var player_global_pos = _player_ref.global_position
		var direction_to_mouse = (mouse_pos - player_global_pos)

		if direction_to_mouse.length() > _player_max_teleport_range:
			target_position = player_global_pos + direction_to_mouse.normalized() * _player_max_teleport_range
		else:
			target_position = mouse_pos

func _is_current_target_colliding() -> bool:
	var query_params = PhysicsPointQueryParameters2D.new()
	query_params.position = global_position
	query_params.collide_with_bodies = true
	query_params.exclude = [_player_ref]

	var collisions = get_world_2d().direct_space_state.intersect_point(query_params)
	return not collisions.is_empty()

func perform_teleport() -> void:
	if _player_ref and _player_teleport_cooldown_ref:
		var has_enough_mana: bool = false
		if _player_ref.has_method("get_current_mana"):
			has_enough_mana = _player_ref.get_current_mana() >= teleport_mana_cost
		elif _player_ref.has_node("current_mana"):
			has_enough_mana = _player_ref.current_mana.value >= teleport_mana_cost
		elif _player_ref.has_method("get") and _player_ref.get("current_mana") != null:
			has_enough_mana = _player_ref.current_mana >= teleport_mana_cost
		else:
			has_enough_mana = _player_ref.current_mana >= teleport_mana_cost

		var can_teleport = _player_teleport_cooldown_ref.is_stopped() \
							and not _is_current_target_colliding() \
							and has_enough_mana

		if can_teleport:
			var final_position = global_position
			_player_ref.global_position = final_position
			_player_ref.velocity = Vector2.ZERO
			_player_teleport_cooldown_ref.start()
			_player_ref.current_mana = max(0, _player_ref.current_mana - teleport_mana_cost) 
			_player_ref.update_mana_bar() 
			if _player_ref.has_node("Timer_mana_regen"): 
				_player_ref.start_mana_regen.start()
			else:
				print("Error: Player does not have 'Timer_mana_regen' node.")


		queue_free() 
	else:
		queue_free()

func cancel_teleport() -> void:
	queue_free()

func _exit_tree() -> void:
	pass
