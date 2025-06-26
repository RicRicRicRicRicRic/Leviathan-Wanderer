# chap1_final_room.gd
extends Node2D

@onready var area2D_exit: Area2D = $Area2D_exit

var card_selection_ui_scene: PackedScene = preload("res://scene/cards/arcane_cards.tscn") 
@export var restart_level_path: String = "res://scene/Chapter1/level_1_Start.tscn" 
@export var boss_level_path: String = "res://scene/Chapter1/scyphozoa_rex_room.tscn" 
var _instanced_card_ui: CanvasLayer = null

func _ready() -> void:
	area2D_exit.body_entered.connect(_on_area_2d_exit_body_entered)

func _on_area_2d_exit_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		area2D_exit.set_deferred("monitoring", false)
		GlobalGameState.level_completion_count += 1 

		_instanced_card_ui = card_selection_ui_scene.instantiate()
		get_tree().root.add_child(_instanced_card_ui)
		if _instanced_card_ui.has_signal("card_chosen"):
			_instanced_card_ui.card_chosen.connect(_on_card_selection_complete)
		else:
			if GlobalGameState.level_completion_count >= 3:
				get_tree().change_scene_to_file(boss_level_path)
				GlobalGameState.level_completion_count = 0 
			else:
				get_tree().change_scene_to_file(restart_level_path)

func _on_card_selection_complete() -> void:
	if _instanced_card_ui and _instanced_card_ui.is_connected("card_chosen", Callable(self, "_on_card_selection_complete")):
		_instanced_card_ui.card_chosen.disconnect(_on_card_selection_complete)
	if GlobalGameState.level_completion_count >= 3:
		get_tree().change_scene_to_file(boss_level_path)
		GlobalGameState.level_completion_count = 0 
	else:
		get_tree().change_scene_to_file(restart_level_path)
