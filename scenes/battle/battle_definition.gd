class_name BattleDefinition
extends RefCounted
## Route configuration only; runtime progress belongs to BattleManager.
enum BattleType { NORMAL, ELITE, BOSS }
enum RewardType { NONE, NORMAL, ELITE }
var number: int
var type: BattleType
var enemies: Array[PackedScene] = []
var spawn_positions: Array[Vector2] = []
var special_label: String = ""
var reward_type: RewardType = RewardType.NORMAL
var shop_after: bool = false
var placeholder: bool = false

func _init(battle_number: int, battle_type: BattleType, composition: Array[PackedScene]) -> void:
	number = battle_number
	type = battle_type
	enemies.assign(composition)

func type_label() -> String:
	return BattleType.keys()[type]
