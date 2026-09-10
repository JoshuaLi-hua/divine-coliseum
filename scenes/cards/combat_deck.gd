class_name CombatDeck
extends RefCounted
## Each integer identifies a physical card copy; definitions may be shared.
const HAND_SIZE: int = 3
var definitions: Array[CardData] = []
var draw_pile: Array[int] = []
var hand: Array[int] = []
var discard_pile: Array[int] = []

func initialize(cards: Array[CardData]) -> void:
	definitions = cards.duplicate()
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	for id: int in range(definitions.size()):
		draw_pile.append(id)
	draw_pile.shuffle()
	_draw_to_hand()

func play(card_id: int) -> void:
	if not hand.has(card_id):
		return
	hand.erase(card_id)
	discard_pile.append(card_id)
	_draw_to_hand()

func _draw_to_hand() -> void:
	while hand.size() < HAND_SIZE:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			draw_pile.assign(discard_pile)
			discard_pile.clear()
			draw_pile.shuffle()
		hand.append(draw_pile.pop_back())

func add_card(data: CardData) -> int:
	# Definitions are append-only: the next index is always a fresh logical ID.
	var card_id: int = definitions.size()
	definitions.append(data)
	discard_pile.append(card_id)
	return card_id

func add_reward(data: CardData) -> int:
	return add_card(data)

func get_all_logical_cards() -> Dictionary:
	var cards: Dictionary = {}
	for id: int in range(definitions.size()):
		if definitions[id] != null:
			cards[id] = definitions[id]
	return cards

func remove_card_by_id(id: int) -> bool:
	if not get_all_logical_cards().has(id) or get_all_logical_cards().size() <= HAND_SIZE:
		return false
	var was_in_hand: bool = hand.has(id)
	draw_pile.erase(id)
	hand.erase(id)
	discard_pile.erase(id)
	# Keep the index reserved forever; surviving IDs never shift.
	definitions[id] = null
	if was_in_hand:
		_draw_to_hand()
	return true
