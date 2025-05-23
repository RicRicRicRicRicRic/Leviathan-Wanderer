# scyphozoa_rex_room.gd
extends Node2D

@onready var boss_entrance: Area2D = $Area2D_boss_entrance
@onready var scyphozoa_rex_boss: CharacterBody2D = $"ScyphozoaRex-boss"
@onready var disable_left_blockade: Area2D = $Area2D_disalbe_blcok
@onready var blockade_left: Sprite2D = $Sprite2D_block_Left

@export var target_boss_y_position: float = -544.0
@export var boss_move_duration: float = 2.75

func _ready() -> void:
	boss_entrance.body_entered.connect(_on_boss_entrance_body_entered)
	disable_left_blockade.body_entered.connect(_on_disable_left_blockade_body_entered)
	# Ensure the blockade is initially enabled if it should be
	blockade_left.visible = true
	# Assuming blockade_left has a collision child, enable/disable it too
	if blockade_left.has_node("StaticBody2D"):
		blockade_left.get_node("StaticBody2D").set_physics_process(true)
		blockade_left.get_node("StaticBody2D").set_process_mode(Node.PROCESS_MODE_INHERIT)


func _on_boss_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var tween = create_tween()
		tween.tween_property(scyphozoa_rex_boss, "global_position:y", target_boss_y_position, boss_move_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		boss_entrance.set_deferred("monitoring", false)
		boss_entrance.set_deferred("monitorable", false)
		# Re-enable blockade_left when player enters boss_entrance area
		blockade_left.visible = true
		if blockade_left.has_node("StaticBody2D"):
			blockade_left.get_node("StaticBody2D").set_physics_process(true)
			blockade_left.get_node("StaticBody2D").set_process_mode(Node.PROCESS_MODE_INHERIT)

func _on_disable_left_blockade_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Disable blockade_left when player enters disable_left_blockade area
		blockade_left.visible = false
		if blockade_left.has_node("StaticBody2D"):
			blockade_left.get_node("StaticBody2D").set_physics_process(false)
			blockade_left.get_node("StaticBody2D").set_process_mode(Node.PROCESS_MODE_DISABLED)
