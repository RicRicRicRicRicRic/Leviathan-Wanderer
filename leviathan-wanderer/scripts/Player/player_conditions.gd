#player_conditions.gd
extends Control

@onready var player: Node = get_tree().get_first_node_in_group("player")
@onready var health_bar: ProgressBar = $ProgressBar_health
@onready var damage_bar: ProgressBar = $ProgressBar_health/ProgressBar_damage
@onready var hp_update_timer: Timer = $Timer
@onready var mana_bar: ProgressBar = $ProgressBar_mana # The main mana bar
@onready var combo_bar: ProgressBar = $ProgressBar_combo_meter # New: Combo progress bar

var depleting: bool = false
var damage_start_value: float = 0.0
var damage_target_value: float = 0.0
var damage_elapsed: float = 0.0

var mana_lerp_speed: float = 5.0 # Control how fast the mana bar interpolates (adjust as needed)
var combo_lerp_speed: float = 10.0 # New: Control how fast the combo bar interpolates (adjust as needed)

var regen_rate := 5.0 # This variable seems unused in this script, but kept as per original.

func _ready() -> void:
	# Connect health bar update timer
	hp_update_timer.timeout.connect(_on_UpdateTimer_timeout)

	add_to_group("player_conditions")

	if player:
		# Initialize health and mana bars
		var initial_health_percent: float = float(player.current_health) / float(player.max_health) * 100.0
		health_bar.value = initial_health_percent
		damage_bar.value = initial_health_percent # Initialize damage bar to full health

		var initial_mana_percent: float = float(player.current_mana) / float(player.max_mana) * 100.0
		mana_bar.value = initial_mana_percent

		# New: Initialize combo bar
		if player.has_method("get_max_combo_meter"): # Check if method exists (good practice)
			combo_bar.max_value = player.get_max_combo_meter()
		else: # Fallback if max_combo_meter is a direct property
			combo_bar.max_value = player.max_combo_meter # Set max value for the combo bar
		combo_bar.value = player.combo_meter # Initialize combo bar value

func _process(delta: float) -> void:
	# Health bar interpolation logic (for damage overlay)
	var hp_percent: float = float(player.current_health) / float(player.max_health) * 100.0
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

	# Mana bar interpolation logic (direct lerp on the main mana bar)
	var mana_percent: float = float(player.current_mana) / float(player.max_mana) * 100.0
	# Only lerp if the current visual value is different from the target value
	if not is_equal_approx(mana_bar.value, mana_percent):
		mana_bar.value = lerp(mana_bar.value, mana_percent, delta * mana_lerp_speed)

	# New: Combo bar interpolation logic
	# Ensure player and max_combo_meter are valid before calculating percent
	if player and player.max_combo_meter > 0:
		# Directly lerp the combo_bar.value towards player.combo_meter
		# The ProgressBar itself will handle displaying this value as a percentage of its max_value
		if not is_equal_approx(combo_bar.value, float(player.combo_meter)):
			combo_bar.value = lerp(combo_bar.value, float(player.combo_meter), delta * combo_lerp_speed)

func _on_UpdateTimer_timeout() -> void:
	# Health bar "damage" overlay update
	damage_start_value = damage_bar.value
	damage_target_value = health_bar.value
	damage_elapsed = 0.0
	depleting = true
