#player_conditions.gd
extends Control

@onready var player: Node = get_tree().get_first_node_in_group("player")
@onready var health_bar: ProgressBar = $ProgressBar_health
@onready var damage_bar: ProgressBar = $ProgressBar_health/ProgressBar_damage
@onready var hp_update_timer: Timer = $Timer
@onready var mana_bar: ProgressBar = $ProgressBar_mana 
@onready var combo_bar: ProgressBar = $ProgressBar_combo_meter 

var depleting: bool = false
var damage_start_value: float = 0.0
var damage_target_value: float = 0.0
var damage_elapsed: float = 0.0

var mana_lerp_speed: float = 5.0 
var combo_lerp_speed: float = 10.0 

var regen_rate := 5.0 

func _ready() -> void:
	hp_update_timer.timeout.connect(_on_UpdateTimer_timeout)

	add_to_group("player_conditions")

	if player:
		var initial_health_percent: float = float(player.current_health) / float(player.effective_max_health) * 100.0
		health_bar.value = initial_health_percent
		damage_bar.value = initial_health_percent 

		var initial_mana_percent: float = float(player.current_mana) / float(player.effective_max_mana) * 100.0
		mana_bar.value = initial_mana_percent

		if player.has_method("get_max_combo_meter"):
			combo_bar.max_value = player.get_max_combo_meter()
		else: 
			combo_bar.max_value = player.max_combo_meter
		combo_bar.value = player.combo_meter 

func _process(delta: float) -> void:
	var hp_percent: float = float(player.current_health) / float(player.effective_max_health) * 100.0
	if health_bar.value != hp_percent:
		health_bar.value = hp_percent
		hp_update_timer.start()

	if depleting:
		damage_elapsed += delta
		var t: float = clamp(damage_elapsed / hp_update_timer.wait_time, 0.0, 1.0)
		damage_bar.value = lerp(damage_start_value, damage_target_value, t)
		if t >= 1.0:
			depleting = false
			damage_bar.value = damage_target_value

	var mana_percent: float = float(player.current_mana) / float(player.effective_max_mana) * 100.0
	if not is_equal_approx(mana_bar.value, mana_percent):
		mana_bar.value = lerp(mana_bar.value, mana_percent, delta * mana_lerp_speed)

	if player and player.max_combo_meter > 0:
		if not is_equal_approx(combo_bar.value, float(player.combo_meter)):
			combo_bar.value = lerp(combo_bar.value, float(player.combo_meter), delta * combo_lerp_speed)

func _on_UpdateTimer_timeout() -> void:
	damage_start_value = damage_bar.value
	damage_target_value = health_bar.value
	damage_elapsed = 0.0
	depleting = true
