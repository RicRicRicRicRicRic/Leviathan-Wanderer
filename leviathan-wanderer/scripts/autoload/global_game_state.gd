# global_game_state.gd
extends Node

var _first_ready_executed: bool = false 
var game_chap_room_value: int = 6

# --- Player Base Stats & Modifiers ---
# These will be reset to their default values on death.
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
var projectile_mana_cost_multiplier: float = 1.0 

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

# --- Teleport Modifiers ---
var teleport_cooldown_multiplier: float = 1.0
var teleport_range_multiplier: float = 1.0
var teleport_mana_cost_multiplier: float = 1.0 

# --- Laser Modifiers ---
var laser_combo_multiplier: float = 1.0
var laser_damage_multiplier: float = 1.0

# --- Game Progression ---
var chapter1_room_completion_count: int = 0 
var chapter2_room_completion_count: int = 0 
var chapter3_room_completion_count: int = 0 
var chosen_arcane_cards: Array[String] = [] # All chosen cards, reset on death

var chapter1_rooms_needed_for_final_room: int = game_chap_room_value
var chapter2_rooms_needed_for_final_room: int = game_chap_room_value
var chapter3_rooms_needed_for_final_room: int = game_chap_room_value

var chapter1_final_room_visits_count: int = 0
var chapter2_final_room_visits_count: int = 0 
var chapter3_final_room_visits_count: int = 0 
var chapter1_final_room_visits_needed_for_boss: int = 3
var chapter2_final_room_visits_needed_for_boss: int = 3 
var chapter3_final_room_visits_needed_for_boss: int = 3 

var current_chapter: int = 1 # To track the player's current chapter (will always reset to 1 for restarts)

func _ready() -> void:
	if not _first_ready_executed:
		# Initialize ALL game state variables to their default values for a fresh start
		_reset_all_game_state_to_defaults()

		randomize() 
		_first_ready_executed = true

# NEW: Helper function to reset ALL game state variables to their initial default values
func _reset_all_game_state_to_defaults() -> void:
	# Reset Player Base Stats
	base_player_max_health = 1000
	base_player_top_speed = 600.0
	base_player_jump_velocity = -700.0
	base_player_max_mana = 1000
	
	# Reset Player Multipliers
	player_max_health_multiplier = 1.0
	player_top_speed_multiplier = 1.0
	player_jump_velocity_multiplier = 1.0
	player_max_mana_multiplier = 1.0
	player_mana_regen_value_multiplier = 1.0
	player_mana_regen_speed_multiplier = 1.0
	projectile_mana_cost_multiplier = 1.0
	projectile_fire_rate_multiplier_effect = 1.0
	projectile_spread_angle_rad = 0.0
	projectile_combo_multiplier = 1.0
	projectile_scale_multiplier = 1.0
	projectile_damage_multiplier = 1.0
	
	can_double_jump = false
	double_jump_mana_cost = 50
	limitless_technique_enabled = false 
	teleport_cooldown_multiplier = 1.0
	teleport_range_multiplier = 1.0
	teleport_mana_cost_multiplier = 1.0 
	laser_combo_multiplier = 1.0
	laser_damage_multiplier = 1.0

	# Reset Game Progression Counters
	chapter1_room_completion_count = 0 
	chapter2_room_completion_count = 0 
	chapter3_room_completion_count = 0 
	chosen_arcane_cards = [] # Clear all chosen cards
	
	chapter1_rooms_needed_for_final_room = game_chap_room_value
	chapter2_rooms_needed_for_final_room = game_chap_room_value
	chapter3_rooms_needed_for_final_room = game_chap_room_value

	chapter1_final_room_visits_count = 0 
	chapter2_final_room_visits_count = 0 
	chapter3_final_room_visits_count = 0 
	chapter1_final_room_visits_needed_for_boss = 3 
	chapter2_final_room_visits_needed_for_boss = 3 
	chapter3_final_room_visits_needed_for_boss = 3 
	current_chapter = 1 # Always reset to Chapter 1

# Centralized function to apply arcane card effects
# This function is called by arcane_cards.gd to modify global state
func _apply_arcane_card_effect(card_name: String) -> void:
	match card_name:
		"daredevil_agility":
			base_player_max_health -= 350 
			player_top_speed_multiplier *= 1.35
			player_jump_velocity_multiplier *= 1.35
		"fortitude":
			base_player_max_health += 500 
			player_top_speed_multiplier *= 0.85 
		"scatter_shot":
			projectile_fire_rate_multiplier_effect = 2.0 
			projectile_spread_angle_rad = deg_to_rad(30.0) 
		"blink_efficiency":
			teleport_cooldown_multiplier = 0.5 
			teleport_range_multiplier = 0.5
			teleport_mana_cost_multiplier = 0.5
		"pulse_accelerator":
			laser_combo_multiplier = 2.0 
			projectile_combo_multiplier = 2.0 
			laser_damage_multiplier = 0.75
		"mana_overdrive": 
			player_max_mana_multiplier *= 0.4 
			player_mana_regen_value_multiplier *= 2.0 
			player_mana_regen_speed_multiplier *= 0.5 
		"heavy_impact_rounds": 
			projectile_fire_rate_multiplier_effect *= 0.5 
			projectile_scale_multiplier *= 1.5 
			projectile_damage_multiplier *= 2.5
			projectile_combo_multiplier = 2.5
			projectile_mana_cost_multiplier *= 2.5 
		"ascendant_leap": 
			can_double_jump = true
		"limitless_technique":
			limitless_technique_enabled = true
		_:
			push_warning("Attempted to apply unknown arcane card effect: " + card_name)

# Resets ALL game state when player dies.
func reset_game_state_on_death() -> void: # Renamed for clarity on full reset
	_reset_all_game_state_to_defaults()
	# No need to re-apply anything, as all cards are reset.
