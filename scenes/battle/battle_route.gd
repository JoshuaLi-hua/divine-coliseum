class_name BattleRoute
extends RefCounted
## The full route, including the final boss encounter.
const MILITIA: PackedScene = preload("res://scenes/units/arena_militia.tscn")
const SWORDSMAN: PackedScene = preload("res://scenes/units/arena_swordsman.tscn")
const GUARD: PackedScene = preload("res://scenes/units/shield_guard.tscn")
const ARCHER: PackedScene = preload("res://scenes/units/arena_archer.tscn")
const ORC: PackedScene = preload("res://scenes/units/wasteland_orc.tscn")
const TROLL: PackedScene = preload("res://scenes/units/cave_troll.tscn")
const SPIDER: PackedScene = preload("res://scenes/units/abyssal_giant_spider.tscn")
const BONECALLER: PackedScene = preload("res://scenes/units/bonecaller.tscn")
const HOLLOW_KING: PackedScene = preload("res://scenes/bosses/hollow_king.tscn")
const NORMAL = BattleDefinition.BattleType.NORMAL
const ELITE = BattleDefinition.BattleType.ELITE
const BOSS = BattleDefinition.BattleType.BOSS
const FORMATION: Array[Vector2] = [
	Vector2(340,-180), Vector2(340,0), Vector2(340,180),
	Vector2(470,-240), Vector2(470,0), Vector2(470,240),
	Vector2(600,-180), Vector2(600,0), Vector2(600,180),
]

static func create() -> Array[BattleDefinition]:
	var route: Array[BattleDefinition] = [
		BattleDefinition.new(1, NORMAL, [MILITIA, MILITIA, SWORDSMAN]),
		BattleDefinition.new(2, NORMAL, [GUARD, SWORDSMAN, SWORDSMAN, ARCHER]),
		BattleDefinition.new(3, NORMAL, [ORC, ORC, TROLL, SPIDER, BONECALLER]),
		BattleDefinition.new(4, NORMAL, [GUARD, SWORDSMAN, SWORDSMAN, ARCHER, ARCHER, ORC, ORC]),
		BattleDefinition.new(5, ELITE, [TROLL, ORC, ORC, SPIDER, SPIDER, BONECALLER, ARCHER]),
		BattleDefinition.new(6, NORMAL, [TROLL, SWORDSMAN, SWORDSMAN, SPIDER, SPIDER, ARCHER, ARCHER]),
		BattleDefinition.new(7, NORMAL, [GUARD, GUARD, ORC, ORC, BONECALLER, ARCHER, ARCHER]),
		BattleDefinition.new(8, NORMAL, [TROLL, ORC, ORC, SPIDER, SPIDER, BONECALLER, BONECALLER]),
		BattleDefinition.new(9, NORMAL, [TROLL, TROLL, GUARD, GUARD, ORC, ORC, BONECALLER, ARCHER, ARCHER]),
		BattleDefinition.new(10, BOSS, [HOLLOW_KING]),
	]
	for definition: BattleDefinition in route:
		definition.spawn_positions.assign(FORMATION.slice(0, definition.enemies.size()))
	# Preserve the original early formations when their positions are unoccupied.
	route[0].spawn_positions.assign([Vector2(420,-180),Vector2(420,0),Vector2(420,180)])
	route[1].spawn_positions.assign([Vector2(420,-180),Vector2(420,0),Vector2(420,180),Vector2(540,-90)])
	route[2].spawn_positions.assign([Vector2(420,-90),Vector2(420,90),Vector2(535,0),Vector2(480,-220),Vector2(590,180)])
	route[3].shop_after = true
	route[4].reward_type = BattleDefinition.RewardType.ELITE
	route[4].special_label = "ELITE BATTLE 5/10"
	route[8].shop_after = true
	route[9].reward_type = BattleDefinition.RewardType.NONE
	route[9].spawn_positions.assign([Vector2(450, 0)])
	return route
