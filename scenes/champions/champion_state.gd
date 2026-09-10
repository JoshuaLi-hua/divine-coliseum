class_name ChampionState
extends RefCounted
## Run state; skills and logical identity are independent of star levels.
signal changed
var selected: ChampionData
var card_id: int = -1
var _learned: Dictionary[StringName, bool] = {}

func _init(data: ChampionData = null) -> void:
	selected = data

func is_champion(id: int) -> bool:
	return selected != null and card_id >= 0 and id == card_id

func has_learned(skill_id: StringName) -> bool:
	return _learned.has(skill_id)

func try_learn(skill_id: StringName, spend_gold: Callable) -> bool:
	if selected == null or has_learned(skill_id):
		return false
	var skill: ChampionSkill = selected.find_skill(skill_id)
	if skill == null or not spend_gold.call(skill.gold_cost):
		return false
	_learned[skill_id] = true
	changed.emit()
	return true

func apply_summon_bonuses(unit: Unit, id: int, data: CardData) -> void:
	if not is_champion(id) or data != selected.card or unit.team != Unit.Team.PLAYER:
		return
	assert(not unit.is_inside_tree())
	for skill: ChampionSkill in selected.skills:
		if has_learned(skill.id):
			unit.max_health += skill.bonus_health
			unit.attack_damage += skill.bonus_damage
	unit.current_health = unit.max_health
	unit.set_meta("champion_id", selected.id)
