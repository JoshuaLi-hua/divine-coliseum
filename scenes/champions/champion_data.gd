class_name ChampionData
extends Resource

@export var id: StringName
@export var display_name: String
@export var card: CardData
@export var skills: Array[ChampionSkill] = []

func find_skill(skill_id: StringName) -> ChampionSkill:
	for skill: ChampionSkill in skills:
		if skill.id == skill_id:
			return skill
	return null
