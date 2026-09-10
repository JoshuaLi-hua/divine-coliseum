class_name ChampionSkill
extends Resource

@export var id: StringName
@export var display_name: String
@export var gold_cost: int = 100
@export var bonus_health: int = 0
@export var bonus_damage: int = 0

func description() -> String:
	var effects: PackedStringArray = []
	if bonus_health != 0:
		effects.append("+%d Max Health" % bonus_health)
	if bonus_damage != 0:
		effects.append("+%d Attack Damage" % bonus_damage)
	return "\n".join(effects)
