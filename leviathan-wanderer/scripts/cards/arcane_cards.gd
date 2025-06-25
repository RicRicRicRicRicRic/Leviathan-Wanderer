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
				_apply_daredevil_agility_effect(player_node)
			"fortitude":
				_apply_fortitude_effect(player_node)
			"scatter_shot":
				_apply_scatter_shot_effect(player_node)
			"blink_efficiency":
				_apply_blink_efficiency_effect(player_node)
			"pulse_accelerator":
				_apply_pulse_accelerator_effect(player_node)
			_:
				pass
	else:
		pass

	card_chosen.emit()
	queue_free()

func _apply_daredevil_agility_effect(player_node: Node) -> void:
	player_node.TOP_SPEED *= 2
	player_node.max_health -= 250
	player_node.current_health = min(player_node.current_health, player_node.max_health)
	player_node.update_health_bar()

func _apply_fortitude_effect(player_node: Node) -> void:
	player_node.max_health += 500
	player_node.TOP_SPEED *= 0.85
	player_node.current_health = min(player_node.current_health, player_node.max_health)
	player_node.update_health_bar()

func _apply_scatter_shot_effect(player_node: Node) -> void:
	player_node.set_meta("projectile_fire_rate_modifier", 2.0)
	player_node.set_meta("projectile_spread_angle", deg_to_rad(30.0))

func _apply_blink_efficiency_effect(player_node: Node) -> void:
	player_node.set_meta("teleport_cooldown_modifier", 0.5)
	player_node.set_meta("teleport_range_modifier", 0.7)

func _apply_pulse_accelerator_effect(player_node: Node) -> void:
	player_node.set_meta("laser_combo_modifier", 1.5) 
	player_node.set_meta("projectile_combo_modifier", 1.5)
	player_node.set_meta("laser_damage_modifier", 0.75)
