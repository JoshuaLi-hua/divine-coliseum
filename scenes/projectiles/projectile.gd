class_name Projectile
extends Node2D
## Target-specific homing projectile; no collision with unrelated units.
@export var damage: int = 0
@export var speed: float = 650.0
@export var lifetime: float = 5.0
var source_team: Unit.Team = Unit.Team.PLAYER
var target: Unit
var _resolved: bool = false
const TARGET_OFFSET: Vector2 = Vector2(0, -30)

func _physics_process(delta: float) -> void:
	if _resolved:
		return
	lifetime -= delta
	if lifetime <= 0.0 or not is_instance_valid(target) or not target.is_inside_tree() or target.is_dead or target.is_queued_for_deletion() or target.team == source_team:
		_finish()
		return
	var destination: Vector2 = target.global_position + TARGET_OFFSET
	var offset: Vector2 = destination - global_position
	rotation = offset.angle()
	var step: float = maxf(0.0, speed) * delta
	# Clamp travel to the target so fast arrows cannot overshoot it.
	if offset.length() <= step:
		global_position = destination
		_resolved = true
		target.take_damage(damage, -offset.normalized())
		queue_free()
	else:
		global_position += offset.normalized() * step

func _finish() -> void:
	_resolved = true
	queue_free()
