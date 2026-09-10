extends Node
## Permanent monster unlocks are loaded once; currencies and Champion are run state.
signal divine_power_changed(value: float)
signal gold_changed(value: int)
var gold: int = 0

const MAX_DIVINE_POWER: float = 10.0
const STARTING_DIVINE_POWER: float = 5.0
const REGENERATION: float = 1.0
var divine_power: float = STARTING_DIVINE_POWER

func reset_divine_power() -> void:
	divine_power = STARTING_DIVINE_POWER
	divine_power_changed.emit(divine_power)

func _process(delta: float) -> void:
	var next: float = minf(MAX_DIVINE_POWER, divine_power + REGENERATION * delta)
	if next != divine_power:
		divine_power = next
		divine_power_changed.emit(divine_power)

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

func get_eligible_cards() -> Array[CardData]:
	return CardCatalog.eligible_cards(get_unlocked_monster_ids())
