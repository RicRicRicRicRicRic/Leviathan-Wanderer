#playerHP.gd
extends Control

@onready var player: Node = get_tree().get_first_node_in_group("player")

@onready var health_bar: ProgressBar = $ProgressBar_health
@onready var damage_bar: ProgressBar = $ProgressBar_health/ProgressBar_damage
@onready var update_timer: Timer = $Timer

var depleting: bool = false
var damage_start_value: float = 0.0
var damage_target_value: float = 0.0
var damage_elapsed: float = 0.0

func _ready() -> void:
	update_timer.timeout.connect(_on_UpdateTimer_timeout)
	add_to_group("playerHP")

func _process(delta: float) -> void:
	var hp_percent: float = float(player.current_health) / float(player.max_health) * 100.0

	if health_bar.value != hp_percent:
		health_bar.value = hp_percent
		update_timer.start()

	if depleting:
		damage_elapsed += delta
		var t: float = clamp(damage_elapsed / update_timer.wait_time, 0.0, 1.0)
		damage_bar.value = lerp(damage_start_value, damage_target_value, t)

		if t >= 1.0:
			depleting = false

func _on_UpdateTimer_timeout() -> void:
	damage_start_value = damage_bar.value
	damage_target_value = health_bar.value
	damage_elapsed = 0.0
	depleting = true
