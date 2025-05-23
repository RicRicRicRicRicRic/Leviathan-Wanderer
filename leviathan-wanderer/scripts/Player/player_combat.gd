extends Node

@export var max_mana: int = 1000
@export var projectile_scene: PackedScene = preload("res://scene/Player_scene/projectile.tscn")
@export var teleport_indicator_scene: PackedScene = preload("res://scene/Player_scene/teleprot.tscn")
@export var laser_scene: PackedScene = preload("res://scene/Player_scene/laser.tscn")
@export var mana_regen_value: int = 3
@export var mana_regen_speed: float = 0.01
@export var max_combo_meter: int = 1000 

@onready var player: Node = get_parent()
@onready var visuals: Node2D = player.get_node("Node2D")
@onready var wep: Node2D = visuals.get_node("WeaponSprite2D")
@onready var proj_marker: Marker2D = wep.get_node("Marker2D")
@onready var laser_marker: Marker2D = wep.get_node("Marker2D_laser")
@onready var teleport_cooldown: Timer = player.get_node("TeleportCDTimer")
@onready var start_mana_regen: Timer = player.get_node("Timer_mana_regen")

var current_mana: int = max_mana
var combo_meter: int = 0
var teleport_cancelled: bool = false
var teleport_indicator_instance: Node2D = null
var is_laser_active: bool = false
var is_mana_regen_active: bool = false
var time_since_last_mana_regen_tick: float = 0.0

func _ready() -> void:
	start_mana_regen.connect("timeout", Callable(self, "_on_mana_regen_delay_timeout"))
	update_mana_bar()

func _physics_process(delta: float) -> void:
	_handle_mana_regen(delta)
	_handle_shooting()
	_handle_teleport()
	_handle_laser()

func _handle_mana_regen(delta: float) -> void:
	if Input.is_action_pressed("Shoot"):
		if not start_mana_regen.is_stopped():
			start_mana_regen.stop()
		is_mana_regen_active = false
		time_since_last_mana_regen_tick = 0.0
	elif Input.is_action_just_released("Shoot"):
		start_mana_regen.start()

	if is_mana_regen_active and current_mana < max_mana:
		time_since_last_mana_regen_tick += delta
		if time_since_last_mana_regen_tick >= mana_regen_speed:
			current_mana = min(current_mana + mana_regen_value, max_mana)
			update_mana_bar()
			time_since_last_mana_regen_tick -= mana_regen_speed
			if current_mana >= max_mana:
				is_mana_regen_active = false
				time_since_last_mana_regen_tick = 0.0

func _handle_shooting() -> void:
	if Input.is_action_pressed("Shoot") and not is_laser_active:
		var mouse_pos: Vector2 = player.get_global_mouse_position()
		Projectile.shoot(proj_marker.global_position, mouse_pos, projectile_scene, player)

func _handle_teleport() -> void:
	if Input.is_action_just_pressed("Teleport"):
		teleport_cancelled = false
		if teleport_indicator_scene and teleport_indicator_instance == null:
			teleport_indicator_instance = teleport_indicator_scene.instantiate()
			player.get_parent().add_child(teleport_indicator_instance)
			if teleport_indicator_instance.has_method("set_teleport_data"):
				teleport_indicator_instance.set_teleport_data(player, teleport_cooldown)
	if Input.is_action_pressed("Teleport"):
		if teleport_indicator_instance:
			var mouse_position = player.get_global_mouse_position()
			teleport_indicator_instance.update_position(mouse_position)
	if Input.is_action_just_pressed("Cancel_input") and Input.is_action_pressed("Teleport"):
		teleport_cancelled = true
		if teleport_indicator_instance:
			teleport_indicator_instance.queue_free()
			teleport_indicator_instance = null
	if Input.is_action_just_released("Teleport"):
		if teleport_indicator_instance:
			var mouse_position = player.get_global_mouse_position()
			teleport_indicator_instance.update_position(mouse_position)
			teleport_indicator_instance.perform_teleport()
			teleport_indicator_instance = null

func _handle_laser() -> void:
	if Input.is_action_just_pressed("Ultimate"):
		if combo_meter == max_combo_meter and not is_laser_active:
			if laser_scene:
				var laser_instance = laser_scene.instantiate()
				laser_instance.global_position = laser_marker.global_position
				player.get_parent().add_child(laser_instance)
				is_laser_active = true
				if laser_instance.has_signal("laser_finished_firing"):
					laser_instance.connect("laser_finished_firing", Callable(self, "_on_laser_finished_firing"))
				combo_meter = 0

func update_mana_bar() -> void:
	var mana_bar_node: Node = player.get_tree().get_first_node_in_group("player_conditions")
	if mana_bar_node:
		var mana_bar_main: ProgressBar = mana_bar_node.get_node("ProgressBar_mana")
		if mana_bar_main:
			mana_bar_main.value = float(current_mana) / float(max_mana) * 100.0

func add_combo(amount: int) -> void:
	combo_meter = min(combo_meter + amount, max_combo_meter)

func _on_laser_finished_firing() -> void:
	is_laser_active = false
	start_mana_regen.start()

func _on_mana_regen_delay_timeout() -> void:
	is_mana_regen_active = true
	time_since_last_mana_regen_tick = 0.0
