class_name BossReinforcements
extends Node
## One shared cap; complete groups only. Sibling summons outlive the boss.
const GROUP: Array[PackedScene] = [
	preload("res://scenes/units/bone_minion.tscn"),
	preload("res://scenes/units/bone_minion.tscn"),
	preload("res://scenes/units/wasteland_orc.tscn"),
]
const CAP: int = 6
var _living: Array[WeakRef] = []
var _cycle: int = 0

func living() -> Array[Unit]:
	var result: Array[Unit] = []
	for index: int in range(_living.size() - 1, -1, -1):
		var unit: Unit = _living[index].get_ref() as Unit
		if not is_instance_valid(unit) or unit.is_dead or not unit.is_inside_tree() or unit.is_queued_for_deletion():
			_living.remove_at(index)
		else:
			result.append(unit)
	return result

func can_summon() -> bool:
	var boss: Unit = get_parent() as Unit
	return is_instance_valid(boss) and not boss.is_dead and not boss.is_queued_for_deletion() and living().size() + GROUP.size() <= CAP

func summon() -> void:
	if not can_summon():
		return
	var boss: Unit = get_parent() as Unit
	for scene: PackedScene in GROUP:
		var unit: Unit = scene.instantiate()
		unit.team = Unit.Team.ENEMY
		unit.position = _position_for(boss, unit)
		boss.get_parent().add_child(unit)
		_living.append(weakref(unit))
		_cycle += 1

func _position_for(boss: Unit, unit: Unit) -> Vector2:
	var best: Vector2
	var best_clearance: float = -INF
	for index: int in range(48):
		var angle: float = float((index + _cycle * 5) % 16) * TAU / 16.0
		var radius: float = 110.0 + float(index / 16) * 45.0
		var point: Vector2 = boss.position + Vector2.from_angle(angle) * radius
		if not Rect2(-630, -265, 1260, 530).has_point(point):
			continue
		var clearance: float = INF
		for node: Node in get_tree().get_nodes_in_group("units"):
			var other: Unit = node as Unit
			if other == null or other.is_dead or other.get_parent() != boss.get_parent():
				continue
			clearance = minf(clearance, point.distance_to(other.position) - 40.0 - unit.engagement_body_radius - other.engagement_body_radius)
		if clearance > best_clearance:
			best_clearance = clearance
			best = point
		if clearance >= 0.0:
			return point
	return best
