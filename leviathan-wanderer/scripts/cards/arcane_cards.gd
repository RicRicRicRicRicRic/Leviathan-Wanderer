# arcane_cards.gd
extends CanvasLayer

@onready var card1: AnimatedSprite2D = $MarginContainer/Node2D_cards/Sprite2D_card1/AnimatedSprite2D
@onready var card2: AnimatedSprite2D = $MarginContainer/Node2D_cards/Sprite2D_card2/AnimatedSprite2D
@onready var card3: AnimatedSprite2D = $MarginContainer/Node2D_cards/Sprite2D_card3/AnimatedSprite2D

func _ready():
	var available_animations = [
		"blink_efficiency",
		"fortitude",
		"pulse_accelerator",
		"scatter_shot",
		"daredevil_agility",
		"pheonix_renewal",
		"heavy_impact_rounds",
		"limitless_technique",
		"mana_overdrive",
		"orbs_retribution",
		"ascendant_leap"
	]

	available_animations.shuffle()

	if available_animations.size() >= 3:
		card1.play(available_animations.pop_front())
		card2.play(available_animations.pop_front())
		card3.play(available_animations.pop_front())
