class_name Unit
extends CharacterBody2D
## Shared targeting, melee movement, and cooldown-based combat.

signal died(unit: Unit)

enum Team { PLAYER, ENEMY }
enum AttackMode { MELEE, PROJECTILE }

@export var attack_mode: AttackMode = AttackMode.MELEE
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 650.0

@export var team: Team = Team.PLAYER
@export var unit_name: String = "Unit"
@export var max_health: int = 1
@export var move_speed: float = 0.0
@export var attack_damage: int = 0
@export var attack_range: float = 0.0
@export var attack_cooldown: float = 1.0

var current_health: int = 0
var current_target: Unit = null
var is_dead: bool = false
var _attack_time_left: float = 0.0
var _hit_tween: Tween
var _visual_rest_modulate: Color
var _attack_tween: Tween
var _visual_rest_position: Vector2

@onready var _health_bar: Node2D = $HealthBar
@onready var _health_fill: ColorRect = $HealthBar/Fill
@onready var _visual: Node2D = $Visual


func _ready() -> void:
	_visual_rest_modulate = _visual.modulate
	_visual_rest_position = _visual.position
	current_health = max_health
	_update_health_bar()
	add_to_group("units")


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_attack_time_left = maxf(0.0, _attack_time_left - delta)
	if not _is_valid_opponent(current_target):
		current_target = _find_nearest_opponent()

	velocity = Vector2.ZERO
	if is_instance_valid(current_target):
		var offset: Vector2 = current_target.global_position - global_position
		var distance: float = offset.length()
		var remaining: float = distance - attack_range
		if remaining > 0.0 and delta > 0.0:
			# Cap the last step so this unit cannot overshoot its melee range.
			velocity = offset.normalized() * minf(move_speed, remaining / delta)
		elif remaining <= 0.0:
			_try_attack()
	move_and_slide()


func _find_nearest_opponent() -> Unit:
	var nearest: Unit = null
	var nearest_distance_squared: float = INF
	for node: Node in get_tree().get_nodes_in_group("units"):
		var candidate: Unit = node as Unit
		if not _is_valid_opponent(candidate):
			continue
		var distance_squared: float = global_position.distance_squared_to(candidate.global_position)
		if distance_squared < nearest_distance_squared:
			nearest = candidate
			nearest_distance_squared = distance_squared
	return nearest


func _is_valid_opponent(candidate: Unit) -> bool:
	return is_instance_valid(candidate) and candidate != self and candidate.is_inside_tree() and not candidate.is_queued_for_deletion() and not candidate.is_dead and candidate.team != team


func _try_attack() -> void:
	if is_dead or _attack_time_left > 0.0 or not _is_valid_opponent(current_target):
		return
	if global_position.distance_to(current_target.global_position) > attack_range:
		return
	_attack_time_left = attack_cooldown
	_play_attack_cue(global_position.direction_to(current_target.global_position))
	if attack_mode == AttackMode.PROJECTILE:
		_fire_projectile()
	else:
		current_target.take_damage(attack_damage)
	if not _is_valid_opponent(current_target):
		current_target = null


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_health = maxi(0, current_health - amount)
	_update_health_bar()
	if current_health == 0:
		_die()
	else:
		_play_hit_cue()


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	current_target = null
	set_physics_process(false)
	remove_from_group("units")
	died.emit(self)
	if _attack_tween != null:
		_attack_tween.kill()
	if _hit_tween != null:
		_hit_tween.kill()
	_health_bar.hide()
	_visual.position = _visual_rest_position
	_visual.modulate = _visual_rest_modulate
	# The fading corpse must not block other living units.
	$CollisionShape2D.set_deferred("disabled", true)
	var death_tween: Tween = create_tween()
	death_tween.tween_property(_visual, "modulate:a", 0.0, 0.2)
	death_tween.tween_callback(queue_free)


func _play_attack_cue(direction: Vector2) -> void:
	if _attack_tween != null:
		_attack_tween.kill()
	_visual.position = _visual_rest_position + direction * 3.0
	_attack_tween = create_tween()
	_attack_tween.tween_property(_visual, "position", _visual_rest_position, 0.12)


func _update_health_bar() -> void:
	_health_fill.scale.x = clampf(float(current_health) / float(maxi(1, max_health)), 0.0, 1.0)


func _play_hit_cue() -> void:
	if _hit_tween != null:
		_hit_tween.kill()
	_visual.modulate = _visual_rest_modulate * Color(0.55, 0.55, 0.55, 1.0)
	_hit_tween = create_tween()
	_hit_tween.tween_property(_visual, "modulate", _visual_rest_modulate, 0.1)


func _fire_projectile() -> void:
	if projectile_scene == null:
		return
	var projectile: Projectile = projectile_scene.instantiate()
	projectile.damage = attack_damage
	projectile.speed = projectile_speed
	projectile.source_team = team
	projectile.target = current_target
	var direction: Vector2 = global_position.direction_to(current_target.global_position)
	var origin: Vector2 = global_position + Vector2(0, -30) + direction * 18.0
	projectile.position = (get_parent() as Node2D).to_local(origin)
	projectile.rotation = direction.angle()
	get_parent().add_child(projectile)
