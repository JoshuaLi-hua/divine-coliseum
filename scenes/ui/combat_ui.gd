extends CanvasLayer

const CARD_SCENE: PackedScene = preload("res://scenes/cards/card.tscn")
const KNIGHT: CardData = preload("res://scenes/cards/ironbound_knight.tres")
const MILITIA: CardData = preload("res://scenes/cards/arena_militia.tres")
var deck: CombatDeck = CombatDeck.new()

@onready var _hand: Control = $Screen/Hand
@onready var _power_label: Label = $Screen/DivinePower
@onready var _region: Node2D = get_parent().get_node("Arena/SummonRegion")

func _ready() -> void:
	GameManager.divine_power_changed.connect(_update_power)
	GameManager.reset_divine_power()
	deck.initialize([KNIGHT, MILITIA, MILITIA, MILITIA])
	_rebuild_hand()

func _update_power(value: float) -> void:
	_power_label.text = "Divine Power: %d / 10" % floori(value)

func _on_dragging_changed(active: bool) -> void:
	_region.visible = active

func _rebuild_hand() -> void:
	for child: Node in _hand.get_children():
		_hand.remove_child(child)
		child.queue_free()
	for slot: int in range(deck.hand.size()):
		var card: SummonCard = CARD_SCENE.instantiate()
		card.card_id = deck.hand[slot]
		card.data = deck.definitions[card.card_id]
		card.position = Vector2(float(slot) * 256.0 - (float(deck.hand.size()) * 256.0 - 16.0) / 2.0, 0)
		_hand.add_child(card)
		card.dragging_changed.connect(_on_dragging_changed)
		card.dropped.connect(_on_card_dropped)
	$Screen/Piles.text = "Draw: %d\nDiscard: %d" % [deck.draw_pile.size(), deck.discard_pile.size()]

func _on_card_dropped(card: SummonCard, viewport_position: Vector2) -> void:
	if card.consumed or not deck.hand.has(card.card_id):
		return
	var data: CardData = deck.definitions[card.card_id]
	if _region.try_summon(data.unit_scene, viewport_position, data.divine_power_cost) == null:
		return
	deck.play(card.card_id)
	# Finish the input callback before replacing its UI nodes.
	for child: SummonCard in _hand.get_children():
		child.consume()
	_rebuild_hand.call_deferred()
