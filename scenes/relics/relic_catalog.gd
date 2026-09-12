class_name RelicCatalog
extends RefCounted
## Shared relic definitions. Look up by stable id, never by UI strings.

const BLOODIED_CROWN: StringName = &"bloodied_crown"
const IRON_IDOL: StringName = &"iron_idol"
const HOURGLASS_OF_THE_GODS: StringName = &"hourglass_of_the_gods"
const WAR_BANNER: StringName = &"war_banner"
const BONE_TALISMAN: StringName = &"bone_talisman"
const GOLDEN_CHALICE: StringName = &"golden_chalice"

const PLAYER_DAMAGE_BONUS: float = 1.10
const PLAYER_MAX_HEALTH_BONUS: float = 1.15
const DIVINE_POWER_REGEN_BONUS: float = 1.25
const PLAYER_MOVE_SPEED_BONUS: float = 1.10
const BONE_MINION_MAX_HEALTH_BONUS: float = 1.25
const CHALICE_GOLD: int = 25

static var _by_id: Dictionary[StringName, RelicData] = {}


static func _ensure() -> void:
	if not _by_id.is_empty():
		return
	_register(BLOODIED_CROWN, "Bloodied Crown", "All PLAYER combat units deal +10% damage.", Color(0.72, 0.22, 0.22))
	_register(IRON_IDOL, "Iron Idol", "All PLAYER combat units gain +15% maximum HP.", Color(0.55, 0.58, 0.62))
	_register(HOURGLASS_OF_THE_GODS, "Hourglass of the Gods", "Divine Power regeneration rate +25%. Maximum Divine Power is unchanged.", Color(0.72, 0.62, 0.28))
	_register(WAR_BANNER, "War Banner", "All PLAYER combat units gain +10% movement speed.", Color(0.62, 0.28, 0.22))
	_register(BONE_TALISMAN, "Bone Talisman", "PLAYER-summoned Bone Minions gain +25% maximum HP.", Color(0.82, 0.82, 0.74))
	_register(GOLDEN_CHALICE, "Golden Chalice", "Gain +25 Gold after each completed battle victory.", Color(0.82, 0.68, 0.22))


static func _register(id: StringName, display_name: String, description: String, accent: Color) -> void:
	var data := RelicData.new()
	data.id = id
	data.display_name = display_name
	data.description = description
	data.accent_color = accent
	_by_id[id] = data


static func is_known(id: StringName) -> bool:
	_ensure()
	return _by_id.has(id)


static func get_relic(id: StringName) -> RelicData:
	_ensure()
	return _by_id.get(id, null)


static func all_relics() -> Array[RelicData]:
	_ensure()
	var relics: Array[RelicData] = []
	for id: StringName in [BLOODIED_CROWN, IRON_IDOL, HOURGLASS_OF_THE_GODS, WAR_BANNER, BONE_TALISMAN, GOLDEN_CHALICE]:
		relics.append(_by_id[id])
	return relics
