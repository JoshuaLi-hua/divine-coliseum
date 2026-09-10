extends CanvasLayer

const REWARD_OVERLAY = preload("res://scenes/ui/reward_overlay.gd")
var _reward: Control
const SHOP_OVERLAY = preload("res://scenes/ui/shop_overlay.gd")
const SHOP_PRICES: Array[int] = [60, 90, 80]
var _shop: Control
var _purchased: Array[bool] = [false, false, false]

const CARD_SCENE: PackedScene = preload("res://scenes/cards/card.tscn")
const KNIGHT: CardData = preload("res://scenes/cards/ironbound_knight.tres")
const MILITIA: CardData = preload("res://scenes/cards/arena_militia.tres")
const SWORDSMAN: CardData = preload("res://scenes/cards/arena_swordsman.tres")
const GUARD: CardData = preload("res://scenes/cards/shield_guard.tres")
const ARCHER: CardData = preload("res://scenes/cards/arena_archer.tres")
var deck: CombatDeck = CombatDeck.new()

@onready var _battle: BattleManager = get_parent().get_node("BattleManager")
@onready var _hand: Control = $Screen/Hand
@onready var _power_label: Label = $Screen/DivinePower
@onready var _region: Node2D = get_parent().get_node("Arena/SummonRegion")

func _ready() -> void:
	GameManager.divine_power_changed.connect(_update_power)
	GameManager.reset_divine_power()
	GameManager.gold_changed.connect(_update_gold)
	GameManager.reset_gold()
	_reward = REWARD_OVERLAY.new()
	$Screen.add_child(_reward)
	_reward.reward_chosen.connect(_choose_reward)
	_reward.continued.connect(_continue_reward)
	_shop = SHOP_OVERLAY.new()
	$Screen.add_child(_shop)
	_shop.purchase_requested.connect(_buy_card)
	_shop.removal_requested.connect(_open_removal)
	_shop.card_removal_requested.connect(_remove_card)
	_shop.leave_requested.connect(_battle.leave_shop)
	deck.initialize([KNIGHT, MILITIA, MILITIA, SWORDSMAN, GUARD, ARCHER, ARCHER])
	_rebuild_hand()
	_battle.changed.connect(_update_battle)

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
		card.set_interaction_locked(_battle.between_battles)
		card.dragging_changed.connect(_on_dragging_changed)
		card.dropped.connect(_on_card_dropped)
	$Screen/Piles.text = "Draw: %d\nDiscard: %d" % [deck.draw_pile.size(), deck.discard_pile.size()]

func _on_card_dropped(card: SummonCard, viewport_position: Vector2) -> void:
	if _battle.between_battles or card.consumed or not deck.hand.has(card.card_id):
		return
	var data: CardData = deck.definitions[card.card_id]
	if _region.try_summon(data.unit_scene, viewport_position, data.divine_power_cost) == null:
		return
	deck.play(card.card_id)
	for child: SummonCard in _hand.get_children():
		child.consume()
	_rebuild_hand.call_deferred()

func _update_battle() -> void:
	$Screen/BattleStatus.text = "Battle %d / %d\nEnemies: %d" % [_battle.current_battle, _battle.BATTLES.size(), _battle.active_enemies.size()]
	$Screen/BattleMessage.text = "VICTORY" if _battle.victory else ("BATTLE CLEARED" if _battle.between_battles else "")
	if _battle.between_battles and not _battle.shop_open:
		if not _reward.visible:
			_reward.open()
	else:
		_reward.hide()
	_shop.visible = _battle.shop_open
	_refresh_shop()
	for card: SummonCard in _hand.get_children():
		card.set_interaction_locked(_battle.between_battles)
	if _battle.between_battles:
		_region.hide()

func _update_gold(value: int) -> void:
	$Screen/Gold.text = "Gold: %d" % value
	_refresh_shop()

func _choose_reward(index: int) -> void:
	if index < 0 or index > 2 or not _battle.claim_reward():
		return
	if index == 2:
		GameManager.add_gold(75)
	else:
		deck.add_reward(SWORDSMAN if index == 0 else ARCHER)
	$Screen/Piles.text = "Draw: %d\nDiscard: %d" % [deck.draw_pile.size(),deck.discard_pile.size()]
	_reward.mark_selected(index)

func _continue_reward() -> void:
	_battle.continue_after_reward()

func _refresh_shop() -> void:
	if is_instance_valid(_shop):
		_shop.refresh(GameManager.gold, _purchased, deck.get_all_logical_cards().size())

func _buy_card(index: int) -> void:
	if not _battle.shop_open or _shop.selecting or index < 0 or index >= SHOP_PRICES.size() or _purchased[index]:
		return
	if not GameManager.try_spend_gold(SHOP_PRICES[index]):
		return
	_purchased[index] = true
	deck.add_card([SWORDSMAN, GUARD, ARCHER][index])
	_rebuild_hand()
	_refresh_shop()

func _open_removal() -> void:
	if _battle.shop_open and GameManager.gold >= 50 and deck.get_all_logical_cards().size() > 3:
		_shop.open_selection(deck.get_all_logical_cards())

func _remove_card(id: int) -> void:
	if not _battle.shop_open or not _shop.selecting or GameManager.gold < 50:
		return
	if not deck.remove_card_by_id(id):
		return
	GameManager.try_spend_gold(50)
	_shop.close_selection()
	_rebuild_hand()
	_refresh_shop()
