# arcane_cards.gd
extends CanvasLayer

signal card_chosen

@onready var card1: AnimatedSprite2D = $MarginContainer/Node2D_cards/Sprite2D_card1/AnimatedSprite2D
@onready var card2: AnimatedSprite2D = $MarginContainer/Node2D_cards/Sprite2D_card2/AnimatedSprite2D
@onready var card3: AnimatedSprite2D = $MarginContainer/Node2D_cards/Sprite2D_card3/AnimatedSprite2D
@onready var card1_bttn: Button = $MarginContainer/Node2D_cards/Sprite2D_card1/Button
@onready var card2_bttn: Button = $MarginContainer/Node2D_cards/Sprite2D_card2/Button
@onready var card3_bttn: Button = $MarginContainer/Node2D_cards/Sprite2D_card3/Button
@onready var card_animation: AnimationPlayer = $MarginContainer/Node2D_cards/AnimationPlayer

var cards: Array[AnimatedSprite2D]
var card_buttons: Array[Button]

var card_target_scales: Array[Vector2] = [Vector2(1,1), Vector2(1,1), Vector2(1,1)]

const SCALE_LERP_SPEED = 10.0

func _ready():
	cards = [card1, card2, card3]
	card_buttons = [card1_bttn, card2_bttn, card3_bttn]

	var available_animations = [
		"blink_efficiency",
		"fortitude",
		"pulse_accelerator",
		"scatter_shot",
		"daredevil_agility",
		"mana_overdrive",
		"heavy_impact_rounds",
		"ascendant_leap" 
	]

	available_animations.shuffle()

	if available_animations.size() >= 3:
		card1.play(available_animations.pop_front())
		card2.play(available_animations.pop_front())
		card3.play(available_animations.pop_front())

	for i in range(card_buttons.size()):
		var card_index = i
		card_buttons[i].mouse_entered.connect(func(): _on_card_button_mouse_entered(card_index))
		card_buttons[i].mouse_exited.connect(func(): _on_card_button_mouse_exited(card_index))
		card_buttons[i].pressed.connect(func(): _on_card_button_pressed(card_index))
		card_buttons[i].disabled = true 

	card_animation.connect("animation_finished", Callable(self, "_on_card_animation_finished"))
	if card_animation.has_animation("default_card_deal_animation"): 
		card_animation.play("default_card_deal_animation")
	else:
		for i in range(card_buttons.size()):
			card_buttons[i].disabled = false


func _process(delta: float):
	for i in range(cards.size()):
		if not card_animation.is_playing():
			cards[i].scale = cards[i].scale.lerp(card_target_scales[i], delta * SCALE_LERP_SPEED)
		else:
			cards[i].scale = Vector2(1,1)


func _on_card_button_mouse_entered(index: int):
	if not card_animation.is_playing():
		card_target_scales[index] = Vector2(1.1,1.1)

func _on_card_button_mouse_exited(index: int):
	if not card_animation.is_playing():
		card_target_scales[index] = Vector2(1, 1)

func _on_card_animation_finished(_anim_name: String):
	for i in range(card_buttons.size()):
		card_buttons[i].disabled = false

func _on_card_button_pressed(index: int):
	for button in card_buttons:
		button.disabled = true
		button.get_parent().get_node("AnimatedSprite2D").scale = Vector2(1,1)
	
	var chosen_animation_name = cards[index].animation

	var player_node = get_tree().get_first_node_in_group("player")

	if player_node:
		match chosen_animation_name:
			"daredevil_agility":
				_apply_daredevil_agility_effect() 
			"fortitude":
				_apply_fortitude_effect() 
			"scatter_shot":
				_apply_scatter_shot_effect()
			"blink_efficiency":
				_apply_blink_efficiency_effect()
			"pulse_accelerator":
				_apply_pulse_accelerator_effect()
			"mana_overdrive": 
				_apply_mana_overdrive_effect()
			"heavy_impact_rounds": 
				_apply_heavy_impact_rounds_effect()
			"ascendant_leap": 
				_apply_ascendant_leap_effect()
			_:
				pass
		
		player_node.update_effective_stats()
		player_node.current_health = min(player_node.current_health, player_node.effective_max_health)
		player_node.update_health_bar()
		player_node.update_mana_bar() 
		player_node.add_combo(0)


	card_chosen.emit()
	queue_free()

func _apply_daredevil_agility_effect() -> void:
	GlobalGameState.player_top_speed_multiplier *= 1.35
	GlobalGameState.base_player_max_health -= 350
	GlobalGameState.player_jump_velocity_multiplier *= 1.35

func _apply_fortitude_effect() -> void:
	GlobalGameState.base_player_max_health += 500
	GlobalGameState.player_top_speed_multiplier *= 0.85 

func _apply_scatter_shot_effect() -> void:
	GlobalGameState.projectile_fire_rate_multiplier_effect = 2.0 
	GlobalGameState.projectile_spread_angle_rad = deg_to_rad(30.0) 

func _apply_blink_efficiency_effect() -> void:
	GlobalGameState.teleport_cooldown_multiplier = 0.5 
	GlobalGameState.teleport_range_multiplier = 0.5
	GlobalGameState.teleport_mana_cost_multiplier = 0.5

func _apply_pulse_accelerator_effect() -> void:
	GlobalGameState.laser_combo_multiplier = 1.5 
	GlobalGameState.projectile_combo_multiplier = 1.5
	GlobalGameState.laser_damage_multiplier = 0.75

func _apply_mana_overdrive_effect() -> void:
	GlobalGameState.player_max_mana_multiplier *= 0.4 
	GlobalGameState.player_mana_regen_value_multiplier *= 2.0 
	GlobalGameState.player_mana_regen_speed_multiplier *= 0.5 

func _apply_heavy_impact_rounds_effect() -> void:
	GlobalGameState.projectile_fire_rate_multiplier_effect *= 0.5 
	GlobalGameState.projectile_scale_multiplier *= 1.5 
	GlobalGameState.projectile_damage_multiplier *= 2.0 

func _apply_ascendant_leap_effect() -> void: 
	GlobalGameState.can_double_jump = true
