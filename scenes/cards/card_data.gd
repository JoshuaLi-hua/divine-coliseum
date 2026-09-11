class_name CardData
extends Resource

@export var display_name: String = "Unit"
@export var divine_power_cost: int = 0
@export var unit_scene: PackedScene
@export var monster: MonsterData

# Immutable per-type profiles, indexed by star level minus one.
@export var health_by_level: Array[int] = []
@export var healing_by_level: Array[int] = []
@export var damage_by_level: Array[int] = []
@export var block_by_level: Array[float] = []

func apply_summon_stats(unit: Unit, level: int) -> void:
	assert(not unit.is_inside_tree())
	var index: int = clampi(level, 1, 3) - 1
	if index < health_by_level.size():
		unit.max_health = health_by_level[index]
	if index < damage_by_level.size():
		unit.attack_damage = damage_by_level[index]
	if index < healing_by_level.size():
		unit.heal_amount = healing_by_level[index]
	if index < block_by_level.size():
		unit.frontal_damage_reduction = block_by_level[index]
	unit.current_health = unit.max_health
	unit.set_meta("upgrade_level", index + 1)
