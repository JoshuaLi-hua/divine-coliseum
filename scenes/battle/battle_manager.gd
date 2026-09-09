class_name BattleManager
extends Node
## Owns only enemy references and progression; player state persists untouched.
signal changed
const ENEMY_SCENE: PackedScene = preload("res://scenes/units/arena_militia.tscn")
const BATTLE_COUNTS: Array[int] = [3, 4, 5]
const SPAWN_POSITIONS: Array[Vector2] = [Vector2(420, -180), Vector2(420, 0), Vector2(420, 180), Vector2(540, -90), Vector2(540, 90)]
var current_battle: int = 0
var active_enemies: Array[Unit] = []
var between_battles: bool = false
var victory: bool = false
@onready var _arena: Node2D = get_parent().get_node("Arena")

func _ready() -> void:
	_start_next_battle.call_deferred()

func _start_next_battle() -> void:
	if victory or not active_enemies.is_empty() or current_battle >= BATTLE_COUNTS.size():
		return
	between_battles = false
	current_battle += 1
	for index: int in range(BATTLE_COUNTS[current_battle - 1]):
		var enemy: Unit = ENEMY_SCENE.instantiate()
		enemy.team = Unit.Team.ENEMY
		enemy.position = SPAWN_POSITIONS[index]
		enemy.died.connect(_on_enemy_died)
		active_enemies.append(enemy)
		_arena.add_child(enemy)
	changed.emit()

func _on_enemy_died(enemy: Unit) -> void:
	if not active_enemies.has(enemy):
		return
	active_enemies.erase(enemy)
	if active_enemies.is_empty():
		if current_battle == BATTLE_COUNTS.size():
			victory = true
		else:
			between_battles = true
			get_tree().create_timer(2.0, false).timeout.connect(_start_next_battle)
	changed.emit()
