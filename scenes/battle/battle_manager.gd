class_name BattleManager
extends Node
## Tracks living arena enemies, including dynamic summons, and battle progression.
signal changed
const MILITIA: PackedScene = preload("res://scenes/units/arena_militia.tscn")
const SWORDSMAN: PackedScene = preload("res://scenes/units/arena_swordsman.tscn")
const GUARD: PackedScene = preload("res://scenes/units/shield_guard.tscn")
const ARCHER: PackedScene = preload("res://scenes/units/arena_archer.tscn")
const ORC: PackedScene = preload("res://scenes/units/wasteland_orc.tscn")
const TROLL: PackedScene = preload("res://scenes/units/cave_troll.tscn")
const SPIDER: PackedScene = preload("res://scenes/units/abyssal_giant_spider.tscn")
const BONECALLER: PackedScene = preload("res://scenes/units/bonecaller.tscn")
const MONSTER_POSITIONS: Array[Vector2] = [Vector2(420, -90), Vector2(420, 90), Vector2(535, 0), Vector2(480, -220), Vector2(590, 180)]
# Slots 0–2 are frontline; slots 3–4 use the farther-right spawn points.
const BATTLES: Array = [
	[MILITIA, MILITIA, SWORDSMAN],
	[GUARD, SWORDSMAN, SWORDSMAN, ARCHER],
	[ORC, ORC, TROLL, SPIDER, BONECALLER],
]
const SPAWN_POSITIONS: Array[Vector2] = [Vector2(420, -180), Vector2(420, 0), Vector2(420, 180), Vector2(540, -90), Vector2(540, 90)]
var current_battle: int = 0
var active_enemies: Array[Unit] = []
var between_battles: bool = false
var victory: bool = false
var reward_selected: bool = false
var shop_open: bool = false
var shop_visited: bool = false
@onready var _arena: Node2D = get_parent().get_node("Arena")

func _ready() -> void:
	get_tree().node_added.connect(_register_enemy)
	for node: Node in get_tree().get_nodes_in_group("units"):
		_register_enemy(node)
	_start_next_battle.call_deferred()

func _start_next_battle() -> void:
	if shop_open or (current_battle == 2 and not shop_visited):
		return
	if (current_battle > 0 and not reward_selected) or victory or not active_enemies.is_empty() or current_battle >= BATTLES.size():
		return
	between_battles = false
	reward_selected = false
	current_battle += 1
	for index: int in range(BATTLES[current_battle - 1].size()):
		var enemy_scene: PackedScene = BATTLES[current_battle - 1][index]
		var enemy: Unit = enemy_scene.instantiate()
		enemy.team = Unit.Team.ENEMY
		enemy.position = MONSTER_POSITIONS[index] if current_battle == 3 else SPAWN_POSITIONS[index]
		_arena.add_child(enemy)
	changed.emit()

func _register_enemy(node: Node) -> void:
	var enemy: Unit = node as Unit
	if enemy == null or enemy.team != Unit.Team.ENEMY or enemy.is_dead or not _arena.is_ancestor_of(enemy):
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
	if not is_inside_tree() or current_battle == 0 or between_battles or victory:
		return
	# The arena's living units are authoritative, not the original wave list.
	active_enemies.clear()
	for node: Node in get_tree().get_nodes_in_group("units"):
		var enemy: Unit = node as Unit
		if enemy != null and enemy.team == Unit.Team.ENEMY and not enemy.is_dead and not enemy.is_queued_for_deletion() and _arena.is_ancestor_of(enemy):
			active_enemies.append(enemy)
	if active_enemies.is_empty():
		if current_battle == BATTLES.size():
			victory = true
		else:
			between_battles = true
			reward_selected = false
	changed.emit()

func claim_reward() -> bool:
	if not between_battles or reward_selected or victory:
		return false
	reward_selected = true
	return true

func continue_after_reward() -> void:
	if not between_battles or not reward_selected or victory or shop_open:
		return
	if current_battle == 2 and not shop_visited:
		shop_open = true
		changed.emit()
	else:
		_start_next_battle()

func leave_shop() -> void:
	if not shop_open:
		return
	shop_open = false
	shop_visited = true
	_start_next_battle()
