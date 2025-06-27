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

	var all_possible_animations = [
		"blink_efficiency",
		"heavy_impact_rounds",
		"fortitude",
		"pulse_accelerator",
		"scatter_shot",
		"daredevil_agility",
		"mana_overdrive",
		"ascendant_leap",
		"limitless_technique"
	]

	var available_for_this_selection = []
	for anim_name in all_possible_animations:
		# Since all cards reset on death, we only filter by what's already chosen in the *current* run
		# if GlobalGameState.chosen_arcane_cards tracks what's picked in THIS run.
		# However, for a full reset on death, if GlobalGameState.chosen_arcane_cards is cleared,
		# all cards effectively become available again.
		# This means, for a strict full reset, this 'if' condition might not be needed
		# if the expectation is all cards are always available after death.
		# Assuming you still want to prevent picking the SAME card multiple times in ONE run.
		if not GlobalGameState.chosen_arcane_cards.has(anim_name):
			available_for_this_selection.append(anim_name)

	available_for_this_selection.shuffle()

	# Assign animations to cards, handling cases where fewer than 3 are available
	var cards_to_show = min(3, available_for_this_selection.size())
	for i in range(3):
		if i < cards_to_show:
			cards[i].play(available_for_this_selection.pop_front())
			cards[i].get_parent().visible = true # Ensure card is visible
		else:
			cards[i].get_parent().visible = false # Hide unused cards
			card_buttons[i].disabled = true # Disable button for hidden card


	for i in range(card_buttons.size()):
		var card_index = i
		card_buttons[i].mouse_entered.connect(func(): _on_card_button_mouse_entered(card_index))
		card_buttons[i].mouse_exited.connect(func(): _on_card_button_mouse_exited(card_index))
		# Ensure only visible cards have their buttons connected and enabled after animation
		if cards[i].get_parent().visible:
			card_buttons[i].pressed.connect(func(): _on_card_button_pressed(card_index))
			card_buttons[i].disabled = true # Disable initially until animation finishes
		else:
			card_buttons[i].disabled = true # Keep disabled if card is not visible


	card_animation.connect("animation_finished", Callable(self, "_on_card_animation_finished"))
	if card_animation.has_animation("default_card_deal_animation"): 
		card_animation.play("default_card_deal_animation")
	else:
		# If animation is missing, enable buttons for visible cards immediately
		for i in range(card_buttons.size()):
			if cards[i].get_parent().visible:
				card_buttons[i].disabled = false


func _process(delta: float):
	for i in range(cards.size()):
		# Only lerp scale if the card is visible and animation is not playing
		if cards[i].get_parent().visible and not card_animation.is_playing():
			cards[i].scale = cards[i].scale.lerp(card_target_scales[i], delta * SCALE_LERP_SPEED)
		else:
			cards[i].scale = Vector2(1,1) # Reset scale if animation is playing or card is hidden


func _on_card_button_mouse_entered(index: int):
	# Only scale if the card is visible and animation is not playing
	if cards[index].get_parent().visible and not card_animation.is_playing():
		card_target_scales[index] = Vector2(1.1,1.1)

func _on_card_button_mouse_exited(index: int):
	# Only scale if the card is visible and animation is not playing
	if cards[index].get_parent().visible and not card_animation.is_playing():
		card_target_scales[index] = Vector2(1, 1)

func _on_card_animation_finished(_anim_name: String):
	# Enable buttons only for visible cards
	for i in range(card_buttons.size()):
		if cards[i].get_parent().visible:
			card_buttons[i].disabled = false

func _on_card_button_pressed(index: int):
	# Disable all buttons immediately after one is pressed
	for button in card_buttons:
		button.disabled = true
		# Ensure the AnimatedSprite2D actually exists before trying to access its parent and scale
		if button.get_parent() and button.get_parent().has_node("AnimatedSprite2D"):
			button.get_parent().get_node("AnimatedSprite2D").scale = Vector2(1,1)
	
	var chosen_animation_name = cards[index].animation

	# Add the chosen card to the GlobalGameState.chosen_arcane_cards
	if not GlobalGameState.chosen_arcane_cards.has(chosen_animation_name):
		GlobalGameState.chosen_arcane_cards.append(chosen_animation_name)
	
	# Apply the effect of the chosen card via the centralized GlobalGameState function
	GlobalGameState._apply_arcane_card_effect(chosen_animation_name)

	var player_node = get_tree().get_first_node_in_group("player")

	if player_node:
		player_node.update_effective_stats()
		# Ensure health doesn't exceed new max health if it was reduced by a card
		player_node.current_health = min(player_node.current_health, player_node.effective_max_health)
		player_node.update_health_bar()
		player_node.update_mana_bar() 
		player_node.add_combo(0) # Not clear what this does here, but maintaining existing logic


	card_chosen.emit()
	queue_free()

# Individual _apply_*_effect functions are NOT here. They are handled by GlobalGameState._apply_arcane_card_effect().
# This is a key part of the current structure where arcane_cards.gd applies effects via GlobalGameState,
# and GlobalGameState handles the actual modification of player stats based on that.
