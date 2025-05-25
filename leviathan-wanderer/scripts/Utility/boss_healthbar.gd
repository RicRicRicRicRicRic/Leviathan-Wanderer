extends Control

@onready var health_bar: ProgressBar = $ProgressBar_health
@onready var damage_bar: ProgressBar = $ProgressBar_health/ProgressBar_damage
@onready var hp_update_timer: Timer = $Timer
@onready var no_damage_delay: Timer = $Timer2

var boss: Node = null

var depleting: bool = false
var damage_start_value: float = 0.0
var damage_target_value: float = 0.0
var damage_elapsed: float = 0.0

var regen_rate := 5.0 

var original_position: float 

func _ready() -> void:
	hp_update_timer.timeout.connect(_on_UpdateTimer_timeout)
	no_damage_delay.timeout.connect(_on_no_damage_delay_timeout)

	add_to_group("boss_health")
	call_deferred("_find_boss_node")

	self.visible = false
	original_position = 1732.5 

func _find_boss_node() -> void:
	boss = get_tree().get_first_node_in_group("boss")
	if boss:
		if boss.has_signal("health_changed"):
			boss.health_changed.connect(_on_boss_health_changed)
			var initial_health_percent: float = boss.current_health / boss.max_health * 100.0
			health_bar.value = initial_health_percent
			damage_bar.value = initial_health_percent
		else:
			push_error("Boss does not have 'health_changed' signal.")
	else:
		push_error("Boss node not found in group 'boss' after deferred lookup.")


func _process(delta: float) -> void:
	if depleting:
		damage_elapsed += delta
		var t: float = clamp(damage_elapsed / hp_update_timer.wait_time, 0.0, 1.0)
		damage_bar.value = lerp(damage_start_value, damage_target_value, t)
		if t >= 1.0:
			depleting = false
			damage_bar.value = damage_target_value

func _on_boss_health_changed(new_health_percent: float) -> void:
	health_bar.value = new_health_percent

	depleting = false
	hp_update_timer.stop()

	no_damage_delay.stop() 
	no_damage_delay.start()

	if new_health_percent <= 0.0:
		_animate_death_and_queue_free()

func _on_no_damage_delay_timeout() -> void:
	damage_start_value = damage_bar.value
	damage_target_value = health_bar.value
	damage_elapsed = 0.0
	depleting = true
	hp_update_timer.start()

func _on_UpdateTimer_timeout() -> void:
	pass

func _animate_death_and_queue_free() -> void:
	var tween = create_tween()
	
	var target_x_position = get_viewport_rect().size.x + self.size.x
	var animation_duration = 1.5

	tween.tween_property(self, "position:x", target_x_position, animation_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	tween.finished.connect(queue_free)

func _animate_reveal() -> void:
	self.visible = true
	self.position.x = 2000
	
	var tween = create_tween()
	var animation_duration = 1.5
	
	tween.tween_property(self, "position:x", original_position, animation_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
