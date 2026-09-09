extends Node2D
## Coordinates are local to the arena; inset for the prototype unit silhouette.
const SUMMON_RECT: Rect2 = Rect2(-620, -240, 540, 510)

func _draw() -> void:
	draw_rect(SUMMON_RECT, Color(1, 1, 1, 0.08))
	draw_rect(SUMMON_RECT, Color(0.94, 0.94, 0.94, 0.8), false, 2.0)

func try_summon(unit_scene: PackedScene, viewport_position: Vector2, cost: int) -> Unit:
	var world_position: Vector2 = get_canvas_transform().affine_inverse() * viewport_position
	if not SUMMON_RECT.has_point(to_local(world_position)) or unit_scene == null:
		return null
	for node: Node in get_tree().get_nodes_in_group("units"):
		var unit: Unit = node as Unit
		if unit != null and unit.global_position.distance_to(world_position) < 48.0:
			return null
	var instance: Node = unit_scene.instantiate()
	var summoned: Unit = instance as Unit
	if summoned == null or not GameManager.try_spend(cost):
		instance.free()
		return null
	summoned.team = Unit.Team.PLAYER
	summoned.position = get_parent().to_local(world_position)
	get_parent().add_child(summoned)
	return summoned
