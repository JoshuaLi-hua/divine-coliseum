class_name Unit
extends CharacterBody2D
## Shared team discovery and melee approach. Combat stats remain inert.

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


func _ready() -> void:
	current_health = max_health
	add_to_group("units")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(current_target) or not current_target.is_inside_tree() or current_target.team == team:
		current_target = _find_nearest_opponent()

	velocity = Vector2.ZERO
	if is_instance_valid(current_target):
		var offset: Vector2 = current_target.global_position - global_position
		var distance: float = offset.length()
		var remaining: float = distance - attack_range
		if remaining > 0.0 and delta > 0.0:
			# Cap the last step so this unit cannot overshoot its melee range.
			velocity = offset.normalized() * minf(move_speed, remaining / delta)
	move_and_slide()


func _find_nearest_opponent() -> Unit:
	var nearest: Unit = null
	var nearest_distance_squared: float = INF
	for node: Node in get_tree().get_nodes_in_group("units"):
		var candidate: Unit = node as Unit
		if candidate == null or candidate == self or candidate.team == team:
			continue
		var distance_squared: float = global_position.distance_squared_to(candidate.global_position)
		if distance_squared < nearest_distance_squared:
			nearest = candidate
			nearest_distance_squared = distance_squared
	return nearest
