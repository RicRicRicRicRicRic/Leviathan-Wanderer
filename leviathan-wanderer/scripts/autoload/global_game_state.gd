# global_game_state.gd
extends Node

var _first_ready_executed: bool = false 

# --- Player Base Stats & Modifiers ---
var base_player_max_health: int
var base_player_top_speed: float
var base_player_jump_velocity: float 

var player_max_health_multiplier: float = 1.0
var player_top_speed_multiplier: float = 1.0
var player_jump_velocity_multiplier: float = 1.0

# --- Mana Modifiers ---
var base_player_max_mana: int 
var player_max_mana_multiplier: float = 1.0 
var player_mana_regen_value_multiplier: float = 1.0 
var player_mana_regen_speed_multiplier: float = 1.0 


# --- Projectile Modifiers ---
var projectile_fire_rate_multiplier_effect: float = 1.0
var projectile_spread_angle_rad: float = 0.0
var projectile_combo_multiplier: float = 1.0
var projectile_scale_multiplier: float = 1.0
var projectile_damage_multiplier: float = 1.0

# --- Double Jump Modifiers ---
var can_double_jump: bool = false 
var double_jump_mana_cost: int = 50 

# --- Limitless Technique Modifiers ---
var limitless_technique_enabled: bool = false
var limitless_technique_duration: float = 2.5 # Re-added
var limitless_technique_cooldown: float = 10.0 # Re-added

# --- Teleport Modifiers ---
var teleport_cooldown_multiplier: float = 1.0
var teleport_range_multiplier: float = 1.0
var teleport_mana_cost_multiplier: float = 1.0 

# --- Laser Modifiers ---
var laser_combo_multiplier: float = 1.0
var laser_damage_multiplier: float = 1.0

# --- Game Progression ---
var level_completion_count: int = 0 # NEW: Tracks how many times the player has entered the final room

func _ready() -> void:
	if not _first_ready_executed:

		base_player_max_health = 1000
		base_player_top_speed = 600.0
		base_player_jump_velocity = -700.0
		base_player_max_mana = 1000
		
		player_max_health_multiplier = 1.0
		player_top_speed_multiplier = 1.0
		player_jump_velocity_multiplier = 1.0
		player_max_mana_multiplier = 1.0
		player_mana_regen_value_multiplier = 1.0
		player_mana_regen_speed_multiplier = 1.0
		projectile_fire_rate_multiplier_effect = 1.0
		projectile_spread_angle_rad = 0.0
		projectile_combo_multiplier = 1.0
		projectile_scale_multiplier = 1.0
		projectile_damage_multiplier = 1.0
		can_double_jump = false
		double_jump_mana_cost = 50
		limitless_technique_enabled = false 
		limitless_technique_duration = 2.5 
		limitless_technique_cooldown = 10.0 
		teleport_cooldown_multiplier = 1.0
		teleport_range_multiplier = 1.0
		teleport_mana_cost_multiplier = 1.0 
		laser_combo_multiplier = 1.0
		laser_damage_multiplier = 1.0

		level_completion_count = 0 

		randomize() 
		_first_ready_executed = true
