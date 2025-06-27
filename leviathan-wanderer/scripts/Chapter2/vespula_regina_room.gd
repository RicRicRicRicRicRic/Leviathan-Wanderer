extends Node2D

@onready var boss_entrance: Area2D = $Area2D_boss_entrance
@onready var vespulaRegina_boss: CharacterBody2D = $"VespulaRegina_boss"
@onready var disable_left_blockade: Area2D = $Area2D_disalbe_blcok
@onready var blockade_left: Sprite2D = $Sprite2D_block_Left
@onready var blockade_right: Sprite2D = $Sprite2D_block_Right 
@onready var area2D_boss_hp: Area2D = $Area2D_boss_hp
@onready var boss_room_exit: Area2D = $Area2D_exit

@export var target_boss_y_position: float = -357.0
@export var boss_move_duration: float = 2.75
@export var next_chapter_path: String = "res://scene/Chapter3/chapter__3_start.tscn" 

signal boss_ready_for_attack

func _ready() -> void:
	boss_entrance.body_entered.connect(_on_boss_entrance_body_entered)
	disable_left_blockade.body_entered.connect(_on_disable_left_blockade_body_entered)
	area2D_boss_hp.body_entered.connect(_on_area2d_boss_hp_body_entered) 
	boss_room_exit.body_entered.connect(_on_boss_room_exit_body_entered) 
	if vespulaRegina_boss:
		vespulaRegina_boss.boss_defeated.connect(_on_vespula_regina_boss_defeated)

	blockade_left.visible = true
	if blockade_left.has_node("StaticBody2D"):
		blockade_left.get_node("StaticBody2D").set_physics_process(true)
		blockade_left.get_node("StaticBody2D").set_process_mode(Node.PROCESS_MODE_INHERIT)

func _on_boss_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var tween = create_tween()
		tween.tween_property(vespulaRegina_boss, "global_position:y", target_boss_y_position, boss_move_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		tween.finished.connect(func():
			boss_ready_for_attack.emit()
			print("Boss entrance animation finished. Emitting boss_ready_for_attack signal.")
		)

		boss_entrance.set_deferred("monitoring", false)
		boss_entrance.set_deferred("monitorable", false)
		blockade_left.visible = true
		if blockade_left.has_node("StaticBody2D"):
			blockade_left.get_node("StaticBody2D").set_physics_process(true)
			blockade_left.get_node("StaticBody2D").set_process_mode(Node.PROCESS_MODE_INHERIT)

func _on_disable_left_blockade_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		blockade_left.visible = false
		if blockade_left.has_node("StaticBody2D"):
			blockade_left.get_node("StaticBody2D").set_physics_process(false)
			blockade_left.get_node("StaticBody2D").set_process_mode(Node.PROCESS_MODE_DISABLED)

func _on_area2d_boss_hp_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var boss_health_bar = get_tree().get_first_node_in_group("boss_health")
		if boss_health_bar and boss_health_bar.has_method("_animate_reveal"):
			boss_health_bar._animate_reveal()
			area2D_boss_hp.queue_free()

func _on_vespula_regina_boss_defeated() -> void:
	print("Vespula Regina boss defeated! Freeing right blockade.")
	if blockade_right:
		blockade_right.queue_free()

func _on_boss_room_exit_body_entered(body: Node2D) -> void: 
	if body.is_in_group("player"):
		
		get_tree().call_deferred("change_scene_to_file", next_chapter_path)
		boss_room_exit.set_deferred("monitoring", false)
		boss_room_exit.set_deferred("monitorable", false)
