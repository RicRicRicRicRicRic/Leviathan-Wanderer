# chap1_final_room.gd
extends Node2D

@onready var area2D_exit: Area2D = $Area2D_exit

# Changed from @export var to a hardcoded path using preload()
var card_selection_ui_scene: PackedScene = preload("res://scene/cards/arcane_cards.tscn") # REPLACE with the actual path to your arcane_cards.tscn!
@export var restart_level_path: String = "res://scene/Chapter1/level_1_Start.tscn" # Path to restart the current level

var _instanced_card_ui: CanvasLayer = null

func _ready() -> void:
	# Connect the body_entered signal of the exit area
	area2D_exit.body_entered.connect(_on_area_2d_exit_body_entered)

func _on_area_2d_exit_body_entered(body: Node2D) -> void:
	# Check if the entering body is the player (assuming player is in a "player" group)
	if body.is_in_group("player"):
		# Prevent multiple triggers by deferring the monitoring change
		area2D_exit.set_deferred("monitoring", false)
		


		# Instance and add the card selection UI scene
		_instanced_card_ui = card_selection_ui_scene.instantiate()
		get_tree().root.add_child(_instanced_card_ui)
		
		# Connect to the signal emitted by the card selection UI when a card is chosen
		if _instanced_card_ui.has_signal("card_chosen"):
			_instanced_card_ui.card_chosen.connect(_on_card_selection_complete)
		else:
			# If the signal isn't found, something is wrong with arcane_cards.gd
			# Resume game and transition anyway as a fallback

			get_tree().change_scene_to_file(restart_level_path)

func _on_card_selection_complete() -> void:
	# Resume the game

	
	# Disconnect the signal to prevent multiple calls
	if _instanced_card_ui and _instanced_card_ui.is_connected("card_chosen", Callable(self, "_on_card_selection_complete")):
		_instanced_card_ui.card_chosen.disconnect(_on_card_selection_complete)
	
	# The arcane_cards.gd script already frees itself, so we don't need to do it here.

	# Transition to the next level. The player's modifiers (stored as metadata)
	# will persist across scene changes if the player node is set to persist
	# or if its data is managed by an autoload singleton.
	get_tree().change_scene_to_file(restart_level_path)
