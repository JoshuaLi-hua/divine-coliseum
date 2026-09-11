class_name CombatSummoner
extends Node
## Small reusable component: attach to a Unit and configure a summon scene.
signal summoned(unit: Unit)
@export var summon_scene: PackedScene
@export var summon_cooldown: float = 6.0
@export var max_active_summons: int = 3
@export var spawn_radius: float = 52.0
var _time_left: float
var _summoner: Unit
var _active_summons: Array[WeakRef] = []
var _spawn_cycle: int = 0

func _ready() -> void:
	_summoner = get_parent() as Unit
	_time_left = maxf(0.01, summon_cooldown)

func get_active_summons() -> Array[Unit]:
	var living: Array[Unit] = []
	for index: int in range(_active_summons.size() - 1, -1, -1):
		var unit: Unit = _active_summons[index].get_ref() as Unit
		if not is_instance_valid(unit) or unit.is_dead or not unit.is_inside_tree() or unit.is_queued_for_deletion():
			_active_summons.remove_at(index)
		else:
			living.append(unit)
	return living

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_summoner) or _summoner.is_dead or _summoner.is_queued_for_deletion():
		set_physics_process(false)
		return
	_time_left -= delta
	if _time_left > 0.0:
		return
	# A full cap consumes this cycle too; deaths never trigger an instant refill.
	_time_left = maxf(0.01, summon_cooldown)
	if summon_scene == null or get_active_summons().size() >= max_active_summons:
		return
	var unit: Unit = summon_scene.instantiate() as Unit
	if unit == null:
		return
	unit.team = _summoner.team
	var container: Node2D = _summoner.get_parent() as Node2D
	unit.position = container.to_local(_find_spawn_position(unit))
	# Siblings survive their summoner's death and are cleaned up with the arena.
	container.add_child(unit)
	_active_summons.append(weakref(unit))
	_spawn_cycle += 1
	summoned.emit(unit)

func _find_spawn_position(unit: Unit) -> Vector2:
	var best: Vector2 = _summoner.global_position
	var best_clearance: float = -INF
	for index: int in range(16):
		var angle: float = float((index + _spawn_cycle * 3) % 8) * TAU / 8.0
		var radius: float = spawn_radius + float(index / 8) * Unit.ALLY_SPACING
		var candidate: Vector2 = _summoner.global_position + Vector2.from_angle(angle) * radius
		var clearance: float = INF
		for node: Node in get_tree().get_nodes_in_group("units"):
			var other: Unit = node as Unit
			if other == null or other.is_dead or other.is_queued_for_deletion():
				continue
			clearance = minf(clearance, candidate.distance_to(other.global_position) - Unit.ALLY_SPACING - unit.engagement_body_radius - other.engagement_body_radius)
		if clearance > best_clearance:
			best_clearance = clearance
			best = candidate
		if clearance >= 0.0:
			return candidate
	return best
