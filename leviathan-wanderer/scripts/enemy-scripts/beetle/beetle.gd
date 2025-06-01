# beetle.gd
extends CharacterBody2D

@export var health: int
@export var max_health: int = 600
@export var speed: float = 100.0
@export var wing_rotation_speed: float = 4
@export var player_tracking_rotation_speed: float = 3.5

@export var attack_distance: float = 600
@export var acid_spray: PackedScene = preload("res://scene/enemyscene/beetle/beetle_spary.tscn")

@export var abdomen_modulation_duration: float = 0.65
@export var acid_spray_cooldown: float = 1.5

@onready var visuals: Node2D = $Node2D
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var ray_forward: RayCast2D = $RayCast2D_Forward
@onready var animated_sprite: AnimatedSprite2D = $Node2D/AnimatedSprite2D
@onready var wing_left: Sprite2D = $Node2D/Sprite2D_wing_L
@onready var wing_right: Sprite2D = $Node2D/Sprite2D_wing_R
@onready var abdomen: Sprite2D = $Node2D/Sprite2D_abdomen
@onready var acid_spray_marker: Marker2D = $Node2D/Marker2D

var is_dying: bool = false
var player_node: CharacterBody2D = null

var is_modulating_abdomen: bool = false
var modulation_timer: float = 0.0
var current_acid_spray_cooldown: float = 0.0
var are_wings_open: bool = false
var damage_decrease: float = 0.5

var can_rotate_after_spray: bool = true

func _ready() -> void:
    add_to_group("enemy")
    health = max_health

    var players = get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        player_node = players[0]

    ray_forward.enabled = true

    if ray_forward and player_node:
        ray_forward.add_exception(player_node)

    for node in get_tree().get_nodes_in_group("enemy"):
        if node != self:
            ray_forward.add_exception(node)

    animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)

func _physics_process(delta: float) -> void:
    if is_dying:
        velocity = Vector2.ZERO
        move_and_slide()
        return

    if current_acid_spray_cooldown > 0:
        current_acid_spray_cooldown -= delta

    if not is_instance_valid(player_node):
        player_node = get_tree().get_first_node_in_group("player")

    if player_node:
        var direction_to_player: Vector2 = (player_node.global_position - global_position).normalized()
        var target_angle_to_player: float = direction_to_player.angle() + (PI / 2)
        var distance_to_player = global_position.distance_to(player_node.global_position)

        ray_forward.target_position = player_node.global_position - global_position
        ray_forward.force_raycast_update()

        var final_target_angle: float
        var current_movement_speed = 0.0
        var current_rotation_speed_applied: float

        var forward_colliding = ray_forward.is_colliding() 

        var movement_direction = Vector2.ZERO

        var target_wing_left_rotation_calculated = 0.0
        var target_wing_right_rotation_calculated = 0.0

        final_target_angle = target_angle_to_player + PI
        current_rotation_speed_applied = player_tracking_rotation_speed

        if distance_to_player < attack_distance and not forward_colliding:
            var angle_to_attack_pose = wrapf(visuals.rotation - final_target_angle, -PI, PI)
            var attack_pose_angle_threshold = deg_to_rad(15.0)

            if abs(angle_to_attack_pose) <= attack_pose_angle_threshold:
                target_wing_left_rotation_calculated = deg_to_rad(15.0)
                target_wing_right_rotation_calculated = deg_to_rad(-15.0)
                are_wings_open = true

                if not is_modulating_abdomen and current_acid_spray_cooldown <= 0:
                    is_modulating_abdomen = true
                    modulation_timer = 0.0
                    abdomen.self_modulate = Color(1, 1, 1, 1)
            else:
                target_wing_left_rotation_calculated = 0.0
                target_wing_right_rotation_calculated = 0.0
                are_wings_open = false
                if is_modulating_abdomen:
                    is_modulating_abdomen = false
                    modulation_timer = 0.0
                    abdomen.self_modulate = Color(1, 1, 1, 1)
        else:
            target_wing_left_rotation_calculated = 0.0
            target_wing_right_rotation_calculated = 0.0
            are_wings_open = false
            if is_modulating_abdomen:
                is_modulating_abdomen = false
                modulation_timer = 0.0
                abdomen.self_modulate = Color(1, 1, 1, 1)

        if is_modulating_abdomen:
            modulation_timer += delta
            var t = min(modulation_timer / abdomen_modulation_duration, 1.0)
            var current_rgb_value = lerp(1.0, 2.0, t)
            abdomen.self_modulate = Color(current_rgb_value, current_rgb_value, current_rgb_value, 1.0)

            if modulation_timer >= abdomen_modulation_duration:
                shoot_acid_spray()
                is_modulating_abdomen = false
                abdomen.self_modulate = Color(1, 1, 1, 1)
                current_acid_spray_cooldown = acid_spray_cooldown

        var rotation_epsilon = deg_to_rad(0.1)
        var is_actively_rotating = abs(wrapf(final_target_angle - visuals.rotation, -PI, PI)) > rotation_epsilon

        if is_actively_rotating and can_rotate_after_spray and not forward_colliding:
            animated_sprite.play("move")
        else:
            animated_sprite.play("idle")

        var rotation_step_amount = delta * current_rotation_speed_applied
        
        if can_rotate_after_spray and not forward_colliding:
            var current_visual_rotation_wrapped = wrapf(visuals.rotation, -PI, PI)
            var final_target_angle_wrapped = wrapf(final_target_angle, -PI, PI)
            var angle_diff_visuals = wrapf(final_target_angle_wrapped - current_visual_rotation_wrapped, -PI, PI)

            if abs(angle_diff_visuals) <= rotation_step_amount:
                visuals.rotation = final_target_angle_wrapped
            else:
                visuals.rotation += sign(angle_diff_visuals) * rotation_step_amount

            var current_collider_rotation_wrapped = wrapf(collider.rotation, -PI, PI)
            var angle_diff_collider = wrapf(final_target_angle_wrapped - current_collider_rotation_wrapped, -PI, PI)

            if abs(angle_diff_collider) <= rotation_step_amount:
                collider.rotation = final_target_angle_wrapped
            else:
                collider.rotation += sign(angle_diff_collider) * rotation_step_amount

        wing_left.rotation = lerp_angle(wing_left.rotation, target_wing_left_rotation_calculated, delta * wing_rotation_speed)
        wing_right.rotation = lerp_angle(wing_right.rotation, target_wing_right_rotation_calculated, delta * wing_rotation_speed)

        velocity = movement_direction * current_movement_speed
    else:
        velocity = Vector2.ZERO
        animated_sprite.play("idle")

    move_and_slide()

func take_damage(amount: float) -> void:
    var actual_damage = amount
    if not are_wings_open:
        actual_damage = actual_damage * damage_decrease

    health -= int(actual_damage)
    if health <= 0 and not is_dying:
        is_dying = true
        set_physics_process(false)
        set_process(false)
        collider.set_deferred("disabled", true)
        wing_left.queue_free()
        wing_right.queue_free()
        abdomen.queue_free()
        if are_wings_open:
            animated_sprite.play("death_wings_open")
        else:
            animated_sprite.play("death_wings_closed")

func shoot_acid_spray() -> void:
    if acid_spray and acid_spray_marker and player_node:
        var spray_instance = acid_spray.instantiate()
        spray_instance.global_position = acid_spray_marker.global_position

        var direction_to_player: Vector2 = (player_node.global_position - acid_spray_marker.global_position).normalized()
        spray_instance.global_rotation = direction_to_player.angle()
        get_tree().current_scene.add_child(spray_instance)

        if spray_instance.has_signal("spray_finished_expanding"):
            spray_instance.connect("spray_finished_expanding", self._on_acid_spray_finished_expanding)
        can_rotate_after_spray = false
    else:
        pass

func _on_animated_sprite_animation_finished() -> void:
    if is_dying and (animated_sprite.animation == "death_wings_open" or animated_sprite.animation == "death_wings_closed"):
        queue_free()

func _on_acid_spray_finished_expanding() -> void:
    can_rotate_after_spray = true
