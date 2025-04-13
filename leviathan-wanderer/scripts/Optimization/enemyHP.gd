#enemyHP.gd
extends Control

@export var enemy: Node = null  

@onready var health_bar: ProgressBar = $ProgressBar_health
@onready var damage_bar: ProgressBar = $ProgressBar_health/ProgressBar_damage
@onready var update_timer: Timer = $Timer

var depleting: bool = false
var damage_start_value: float = 0.0
var damage_target_value: float = 0.0
var damage_elapsed: float = 0.0

func _ready() -> void:
	update_timer.wait_time = 1.0   
	update_timer.one_shot = true

	if enemy == null:
		enemy = get_parent()

func _process(delta: float) -> void:
	var current_health: int = enemy.health
	var max_health: int = enemy.max_health
	var hp_percent: float = float(current_health) / float(max_health) * 100.0

	health_bar.value = hp_percent

	if damage_bar.value != hp_percent and not depleting:
		damage_start_value = damage_bar.value
		damage_target_value = hp_percent
		damage_elapsed = 0.0
		depleting = true
		update_timer.start()

	if depleting:
		damage_elapsed += delta
		var t: float = clamp(damage_elapsed / update_timer.wait_time, 0.0, 1.0)
		damage_bar.value = lerp(damage_start_value, damage_target_value, t)
		if t >= 1.0:
			depleting = false

