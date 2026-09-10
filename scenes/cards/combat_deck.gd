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

func add_reward(data: CardData) -> int:
	# Definitions are append-only: the next index is always a fresh logical ID.
	var card_id: int = definitions.size()
	definitions.append(data)
	discard_pile.append(card_id)
	return card_id
