class_name CardCatalog
extends RefCounted
## Shared acquisition catalog. Eligibility uses stable monster IDs, never names.
const SWORDSMAN: CardData = preload("res://scenes/cards/arena_swordsman.tres")
const GUARD: CardData = preload("res://scenes/cards/shield_guard.tres")
const ARCHER: CardData = preload("res://scenes/cards/arena_archer.tres")
const ORC: CardData = preload("res://scenes/cards/wasteland_orc.tres")
const TROLL: CardData = preload("res://scenes/cards/cave_troll.tres")
const SPIDER: CardData = preload("res://scenes/cards/abyssal_giant_spider.tres")
const MONSTER_CARDS: Dictionary = {
	&"wasteland_orc": ORC,
	&"cave_troll": TROLL,
	&"abyssal_giant_spider": SPIDER,
}
const SHOP_PRICES: Dictionary = {
	SWORDSMAN: 60, GUARD: 90, ARCHER: 80,
	ORC: 70, TROLL: 140, SPIDER: 65,
}

static func eligible_cards(unlocked_ids: Array[StringName]) -> Array[CardData]:
	var cards: Array[CardData] = [SWORDSMAN, GUARD, ARCHER]
	for id: StringName in MONSTER_CARDS:
		if unlocked_ids.has(id):
			cards.append(MONSTER_CARDS[id])
	return cards

static func draw_offers(eligible: Array[CardData], count: int) -> Array[CardData]:
	var cards: Array[CardData] = eligible.duplicate()
	cards.shuffle()
	cards.resize(mini(count, cards.size()))
	return cards

static func shop_price(card: CardData) -> int:
	return SHOP_PRICES.get(card, -1)
