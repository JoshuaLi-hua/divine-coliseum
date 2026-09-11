class_name BattleManager
extends Node
## Tracks living arena enemies, including dynamic summons, and battle progression.
signal changed
enum Phase { SETUP, COMBAT, REWARD, SHOP, ADVANCING, BOSS_BOUNDARY }
var route: Array[BattleDefinition] = BattleRoute.create()
var phase: Phase = Phase.SETUP
var current_battle: int = 0
var active_enemies: Array[Unit] = []
var reward_selected: bool = false
var shop_visit: int = 0
var victory: bool = false
var between_battles: bool:
	get: return phase in [Phase.REWARD, Phase.SHOP]
var shop_open: bool:
	get: return phase == Phase.SHOP
var boss_boundary: bool:
	get: return phase == Phase.BOSS_BOUNDARY
@onready var _arena: Node2D = get_parent().get_node("Arena")

func _ready() -> void:
	get_tree().node_added.connect(_register_enemy)
	for node: Node in get_tree().get_nodes_in_group("units"):
		_register_enemy(node)
	_start_next_battle.call_deferred()

func current_definition() -> BattleDefinition:
	return route[current_battle - 1] if current_battle > 0 else null

func is_combat_active() -> bool:
	return phase == Phase.COMBAT

func _start_next_battle() -> void:
	if phase not in [Phase.SETUP, Phase.ADVANCING] or not active_enemies.is_empty() or current_battle >= route.size():
		return
	current_battle += 1
	reward_selected = false
	var definition: BattleDefinition = current_definition()
	if definition.placeholder:
		phase = Phase.BOSS_BOUNDARY
		# Freeze all surviving combat actors, casts, and projectiles, not the UI.
		_arena.process_mode = Node.PROCESS_MODE_DISABLED
		changed.emit()
		return
	phase = Phase.COMBAT
	for index: int in range(definition.enemies.size()):
		var enemy: Unit = definition.enemies[index].instantiate()
		enemy.team = Unit.Team.ENEMY
		enemy.position = _safe_spawn_position(definition.spawn_positions[index], enemy)
		_arena.add_child(enemy)
	changed.emit()

func _safe_spawn_position(preferred: Vector2, enemy: Unit) -> Vector2:
	var candidates: Array[Vector2] = [preferred]
	# Surviving player units may already occupy the next wave's formation.
	for x: float in [260.0, 350.0, 440.0, 530.0, 620.0]:
		for y: float in [-240.0, -120.0, 0.0, 120.0, 240.0]:
			candidates.append(Vector2(x,y))
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(preferred) < b.distance_squared_to(preferred))
	var best: Vector2 = preferred
	var best_clearance: float = -INF
	for point: Vector2 in candidates:
		var clearance: float = INF
		for node: Node in get_tree().get_nodes_in_group("units"):
			var other: Unit = node as Unit
			if other == null or other.is_dead or other.is_queued_for_deletion() or not _arena.is_ancestor_of(other):
				continue
			clearance = minf(clearance, point.distance_to(_arena.to_local(other.global_position)) - 48.0 - enemy.engagement_body_radius - other.engagement_body_radius)
		if clearance >= 0.0:
			return point
		if clearance > best_clearance:
			best_clearance = clearance
			best = point
	return best

func _register_enemy(node: Node) -> void:
	var enemy: Unit = node as Unit
	if not is_combat_active() or enemy == null or enemy.team != Unit.Team.ENEMY or enemy.is_dead or not _arena.is_ancestor_of(enemy):
		return
	if active_enemies.has(enemy):
		return
	active_enemies.append(enemy)
	enemy.died.connect(_on_enemy_died)
	enemy.tree_exiting.connect(_on_enemy_exiting.bind(enemy))
	# Defer UI updates until the newly added unit has completed ready.
	changed.emit.call_deferred()

func _on_enemy_died(enemy: Unit) -> void:
	if not active_enemies.has(enemy):
		return
	GameManager.record_monster_defeat(enemy)
	active_enemies.erase(enemy)
	_check_battle_clear()

func _on_enemy_exiting(enemy: Unit) -> void:
	if not active_enemies.has(enemy):
		return
	active_enemies.erase(enemy)
	_check_battle_clear.call_deferred()

func _check_battle_clear() -> void:
	if not is_inside_tree() or not is_combat_active():
		return
	# The arena's living units are authoritative, not the original wave list.
	active_enemies.clear()
	for node: Node in get_tree().get_nodes_in_group("units"):
		var enemy: Unit = node as Unit
		if enemy != null and enemy.team == Unit.Team.ENEMY and not enemy.is_dead and not enemy.is_queued_for_deletion() and _arena.is_ancestor_of(enemy):
			active_enemies.append(enemy)
	if active_enemies.is_empty():
		reward_selected = false
		if current_definition().reward_type != BattleDefinition.RewardType.NONE:
			phase = Phase.REWARD
		elif current_definition().shop_after:
			_open_shop()
		else:
			phase = Phase.ADVANCING
			_start_next_battle.call_deferred()
	changed.emit()

func can_claim_reward(kind: BattleDefinition.RewardType) -> bool:
	return phase == Phase.REWARD and not reward_selected and current_definition().reward_type == kind

func claim_reward(kind: BattleDefinition.RewardType = BattleDefinition.RewardType.NORMAL) -> bool:
	if not can_claim_reward(kind):
		return false
	reward_selected = true
	return true

func continue_after_reward() -> void:
	if phase != Phase.REWARD or not reward_selected:
		return
	if current_definition().shop_after:
		_open_shop()
	else:
		phase = Phase.ADVANCING
		_start_next_battle()

func _open_shop() -> void:
	phase = Phase.SHOP
	shop_visit += 1
	changed.emit()

func leave_shop() -> void:
	if phase != Phase.SHOP:
		return
	phase = Phase.ADVANCING
	_start_next_battle()
