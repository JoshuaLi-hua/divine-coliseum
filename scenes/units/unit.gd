class_name Unit
extends CharacterBody2D
## Shared targeting, melee movement, and cooldown-based combat.

enum Team { PLAYER, ENEMY }

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
var _attack_tween: Tween
var _visual_rest_position: Vector2

@onready var _visual: Node2D = $Visual


func _ready() -> void:
	_visual_rest_position = _visual.position
	current_health = max_health
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
	current_target.take_damage(attack_damage)
	if not _is_valid_opponent(current_target):
		current_target = null


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_health = maxi(0, current_health - amount)
	if current_health == 0:
		_die()


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	current_target = null
	set_physics_process(false)
	remove_from_group("units")
	if _attack_tween != null:
		_attack_tween.kill()
	queue_free()


func _play_attack_cue(direction: Vector2) -> void:
	if _attack_tween != null:
		_attack_tween.kill()
	_visual.position = _visual_rest_position + direction * 3.0
	_attack_tween = create_tween()
	_attack_tween.tween_property(_visual, "position", _visual_rest_position, 0.12)
