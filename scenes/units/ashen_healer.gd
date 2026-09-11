extends Unit
## Team-based support: follow combat allies, never reserve enemy engagement slots.
@export var heal_radius: float = 180.0
@export var heal_cooldown: float = 2.0
@export var follow_distance: float = 110.0
var _heal_time_left: float = 2.0
var support_target: Unit

func _ready() -> void:
	super._ready()
	_heal_time_left = heal_cooldown

func _valid_ally(ally: Unit) -> bool:
	return is_instance_valid(ally) and ally != self and ally.is_inside_tree() and not ally.is_queued_for_deletion() and not ally.is_dead and ally.team == team

func _find_support_target() -> Unit:
	var nearest: Unit
	var nearest_distance: float = INF
	for node: Node in get_tree().get_nodes_in_group("units"):
		var ally: Unit = node as Unit
		if not _valid_ally(ally) or ally.attack_damage <= 0:
			continue
		var distance: float = global_position.distance_squared_to(ally.global_position)
		if distance < nearest_distance:
			nearest = ally
			nearest_distance = distance
	return nearest

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_heal_time_left -= delta
	if _heal_time_left <= 0.0:
		_heal_time_left = maxf(0.01, heal_cooldown)
		for node: Node in get_tree().get_nodes_in_group("units"):
			var ally: Unit = node as Unit
			if _valid_ally(ally) and ally.current_health < ally.max_health and global_position.distance_squared_to(ally.global_position) <= heal_radius * heal_radius:
				ally.heal(heal_amount)
	if not _valid_ally(support_target) or support_target.attack_damage <= 0:
		support_target = _find_support_target()
	velocity = _positioning_velocity()
	if velocity.length() < 0.5:
		velocity = Vector2.ZERO
	move_and_slide()

func _positioning_velocity() -> Vector2:
	var desired: Vector2 = Vector2.ZERO
	if _valid_ally(support_target):
		var remaining: float = global_position.distance_to(support_target.global_position) - follow_distance
		if remaining > 0.0:
			desired = global_position.direction_to(support_target.global_position) * minf(move_speed, remaining * 6.0)
	return (desired + _ally_separation()).limit_length(move_speed)

func _try_attack() -> void:
	pass
