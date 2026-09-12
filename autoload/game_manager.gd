extends Node
## Permanent monster unlocks are loaded once; currencies, Champion, and relics are run state.
signal divine_power_changed(value: float)
signal gold_changed(value: int)
signal relics_changed
signal focus_command_changed
var gold: int = 0

const MAX_DIVINE_POWER: float = 10.0
const STARTING_DIVINE_POWER: float = 5.0
const REGENERATION: float = 1.0
const FOCUS_TARGET_DURATION: float = 5.0
const FOCUS_TARGET_COOLDOWN: float = 10.0
var divine_power: float = STARTING_DIVINE_POWER
var _owned_relics: Dictionary[StringName, bool] = {}
var _chalice_awarded_battle: int = 0
var focus_remaining: float = 0.0
var focus_cooldown_remaining: float = 0.0
var _focus_target: WeakRef

func reset_divine_power() -> void:
	divine_power = STARTING_DIVINE_POWER
	divine_power_changed.emit(divine_power)

func _process(delta: float) -> void:
	var next: float = minf(MAX_DIVINE_POWER, divine_power + REGENERATION * divine_power_regen_multiplier() * delta)
	if next != divine_power:
		divine_power = next
		divine_power_changed.emit(divine_power)
	_update_focus_command(delta)

func _update_focus_command(delta: float) -> void:
	var changed := false
	if focus_cooldown_remaining > 0.0:
		focus_cooldown_remaining = maxf(0.0, focus_cooldown_remaining - delta)
		changed = true
	if focus_remaining > 0.0:
		focus_remaining = maxf(0.0, focus_remaining - delta)
		changed = true
		if focus_remaining <= 0.0:
			_focus_target = null
	if _focus_target != null and not is_valid_focus_target(_focus_target.get_ref()):
		_focus_target = null
		focus_remaining = 0.0
		changed = true
	if changed:
		focus_command_changed.emit()

func is_focus_ready() -> bool:
	return focus_cooldown_remaining <= 0.0

func is_valid_focus_target(candidate: Variant) -> bool:
	if not is_instance_valid(candidate) or not (candidate is Unit):
		return false
	var unit := candidate as Unit
	return unit.team == Unit.Team.ENEMY and unit.is_inside_tree() and not unit.is_queued_for_deletion() and unit.is_targetable()

func start_focus_target(target: Unit) -> bool:
	if focus_cooldown_remaining > 0.0 or not is_valid_focus_target(target):
		return false
	_focus_target = weakref(target)
	focus_remaining = FOCUS_TARGET_DURATION
	focus_cooldown_remaining = FOCUS_TARGET_COOLDOWN
	focus_command_changed.emit()
	return true

func clear_focus_target(reset_cooldown: bool = false) -> void:
	_focus_target = null
	focus_remaining = 0.0
	if reset_cooldown:
		focus_cooldown_remaining = 0.0
	focus_command_changed.emit()

func reset_focus_command() -> void:
	clear_focus_target(true)

func get_focus_target() -> Unit:
	if _focus_target == null:
		return null
	var target: Unit = _focus_target.get_ref() as Unit
	return target if is_valid_focus_target(target) else null

func get_focus_target_for(unit: Unit) -> Unit:
	if unit == null or unit.team != Unit.Team.PLAYER or not unit.can_attack_enemies() or _focus_target == null:
		return null
	var target := get_focus_target()
	return target if is_valid_focus_target(target) else null

func has_relic(id: StringName) -> bool:
	return _owned_relics.has(id)

func add_relic(id: StringName) -> bool:
	if not RelicCatalog.is_known(id) or _owned_relics.has(id):
		return false
	_owned_relics[id] = true
	_refresh_living_unit_relics()
	relics_changed.emit()
	return true

func remove_relic(id: StringName) -> bool:
	if not _owned_relics.has(id):
		return false
	_owned_relics.erase(id)
	_refresh_living_unit_relics()
	relics_changed.emit()
	return true

func get_owned_relics() -> Array[RelicData]:
	var relics: Array[RelicData] = []
	for data: RelicData in RelicCatalog.all_relics():
		if _owned_relics.has(data.id):
			relics.append(data)
	return relics

func get_eligible_relics() -> Array[RelicData]:
	var relics: Array[RelicData] = []
	for data: RelicData in RelicCatalog.all_relics():
		if not _owned_relics.has(data.id):
			relics.append(data)
	return relics

func draw_relic_offers(count: int) -> Array[RelicData]:
	var relics: Array[RelicData] = get_eligible_relics()
	relics.shuffle()
	relics.resize(mini(count, relics.size()))
	return relics

func reset_relics() -> void:
	_owned_relics.clear()
	_chalice_awarded_battle = 0
	_refresh_living_unit_relics()
	relics_changed.emit()

func toggle_relic(id: StringName) -> bool:
	if has_relic(id):
		return remove_relic(id)
	return add_relic(id)

func player_damage_multiplier() -> float:
	return RelicCatalog.PLAYER_DAMAGE_BONUS if has_relic(RelicCatalog.BLOODIED_CROWN) else 1.0

func player_move_speed_multiplier() -> float:
	return RelicCatalog.PLAYER_MOVE_SPEED_BONUS if has_relic(RelicCatalog.WAR_BANNER) else 1.0

func divine_power_regen_multiplier() -> float:
	return RelicCatalog.DIVINE_POWER_REGEN_BONUS if has_relic(RelicCatalog.HOURGLASS_OF_THE_GODS) else 1.0

func player_max_health_multiplier(unit: Unit) -> float:
	if unit == null or unit.team != Unit.Team.PLAYER:
		return 1.0
	var multiplier: float = 1.0
	if has_relic(RelicCatalog.IRON_IDOL):
		multiplier *= RelicCatalog.PLAYER_MAX_HEALTH_BONUS
	if has_relic(RelicCatalog.BONE_TALISMAN) and unit.is_bone_minion():
		multiplier *= RelicCatalog.BONE_MINION_MAX_HEALTH_BONUS
	return multiplier

func try_award_golden_chalice(battle_index: int) -> void:
	if battle_index <= 0 or not has_relic(RelicCatalog.GOLDEN_CHALICE) or _chalice_awarded_battle == battle_index:
		return
	_chalice_awarded_battle = battle_index
	add_gold(RelicCatalog.CHALICE_GOLD)

func _refresh_living_unit_relics() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	for node: Node in tree.get_nodes_in_group("units"):
		var unit: Unit = node as Unit
		if unit != null and not unit.is_dead:
			unit.refresh_relic_modifiers()

func try_spend(cost: float) -> bool:
	if cost < 0.0 or divine_power < cost:
		return false
	divine_power -= cost
	divine_power_changed.emit(divine_power)
	return true

func reset_gold() -> void:
	gold = 0
	gold_changed.emit(gold)

func add_gold(amount: int) -> void:
	if amount > 0:
		gold += amount
		gold_changed.emit(gold)

func try_spend_gold(cost: int) -> bool:
	if cost < 0 or gold < cost:
		return false
	gold -= cost
	gold_changed.emit(gold)
	return true

const MAIN_CHAMPION: ChampionData = preload("res://scenes/champions/ironbound_knight.tres")
var champion: ChampionState = ChampionState.new(MAIN_CHAMPION)

func reset_champion() -> void:
	champion = ChampionState.new(MAIN_CHAMPION)

func try_learn_champion_skill(skill_id: StringName) -> bool:
	return champion.try_learn(skill_id, try_spend_gold)

signal monster_unlocked(data: MonsterData)
var _unlocked_monsters: Dictionary[StringName, MonsterData] = {}

func _ready() -> void:
	for id: StringName in MonsterProgress.load_ids():
		var card: CardData = CardCatalog.MONSTER_CARDS[id]
		_unlocked_monsters[id] = card.monster

func get_unlocked_monster_ids() -> Array[StringName]:
	return _unlocked_monsters.keys()

func record_monster_defeat(unit: Unit) -> bool:
	if unit.team != Unit.Team.ENEMY or not unit.is_dead or unit.monster == null or unit.monster.id == &"":
		return false
	var id: StringName = unit.monster.id
	if not CardCatalog.MONSTER_CARDS.has(id) or _unlocked_monsters.has(id):
		return false
	var card: CardData = CardCatalog.MONSTER_CARDS[id]
	_unlocked_monsters[id] = card.monster
	MonsterProgress.save_ids(get_unlocked_monster_ids())
	monster_unlocked.emit(card.monster)
	return true


func reset_run_state() -> void:
	reset_divine_power()
	reset_gold()
	reset_champion()
	reset_relics()
	reset_focus_command()

func get_eligible_cards() -> Array[CardData]:
	return CardCatalog.eligible_cards(get_unlocked_monster_ids())
