extends CanvasLayer

const BESTIARY_OVERLAY = preload("res://scenes/ui/bestiary_overlay.gd")
var _bestiary: Control

const UNLOCK_NOTICE = preload("res://scenes/ui/monster_unlock_notice.gd")
var _unlock_notice: Control
const REWARD_OVERLAY = preload("res://scenes/ui/reward_overlay.gd")
var _reward: Control
const ELITE_REWARD_OVERLAY = preload("res://scenes/ui/elite_reward_overlay.gd")
var _elite_reward: Control
var _elite_reward_battle: int = 0
var _elite_relic_offers: Array[RelicData] = []
var _shop_visit: int = 0
const SHOP_OVERLAY = preload("res://scenes/ui/shop_overlay.gd")
const UPGRADE_COST: int = 75
var _shop: Control
var _purchased: Array[bool] = [false, false, false]
var _reward_cards: Array[CardData] = []
var _reward_battle: int = 0
var _shop_cards: Array[CardData] = []
var _restarting: bool = false
const BOSS_HEALTH_UI = preload("res://scenes/ui/boss_health_ui.gd")
const RELIC_HUD = preload("res://scenes/ui/relic_hud.gd")
const FOCUS_TARGET_MARKER = preload("res://scenes/ui/focus_target_marker.gd")
var _boss_ui: Control
var _focus_panel: Panel
var _focus_button: Button
var _focus_selecting: bool = false
var _focus_marker: FocusTargetMarker

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
@onready var _arena: Node2D = get_parent().get_node("Arena")
@onready var _unit_layer: Node2D = get_parent().get_node("Arena/UnitLayer")

func _ready() -> void:
	GameManager.divine_power_changed.connect(_update_power)
	GameManager.gold_changed.connect(_update_gold)
	GameManager.reset_run_state()
	GameManager.champion.changed.connect(_refresh_shop)
	_boss_ui = BOSS_HEALTH_UI.new()
	$Screen.add_child(_boss_ui)
	var relic_hud: RelicHud = RELIC_HUD.new()
	relic_hud.name = "RelicHud"
	relic_hud.position = Vector2(18, 160)
	$Screen.add_child(relic_hud)
	_build_focus_command_ui()
	_focus_marker = FOCUS_TARGET_MARKER.new()
	_focus_marker.hide()
	_unit_layer.add_child(_focus_marker)
	GameManager.focus_command_changed.connect(_update_focus_command_ui)
	_reward = REWARD_OVERLAY.new()
	$Screen.add_child(_reward)
	_reward.reward_chosen.connect(_choose_reward)
	_reward.continued.connect(_continue_reward)
	_elite_reward = ELITE_REWARD_OVERLAY.new()
	$Screen.add_child(_elite_reward)
	_elite_reward.relic_chosen.connect(_choose_elite_relic)
	_shop = SHOP_OVERLAY.new()
	$Screen.add_child(_shop)
	_shop.purchase_requested.connect(_buy_card)
	_shop.removal_requested.connect(_open_removal)
	_shop.card_removal_requested.connect(_remove_card)
	_shop.upgrade_requested.connect(_open_upgrade)
	_shop.card_upgrade_requested.connect(_upgrade_card)
	_shop.training_requested.connect(_open_training)
	_shop.skill_requested.connect(_learn_skill)
	_shop.leave_requested.connect(_battle.leave_shop)
	deck.initialize([KNIGHT, MILITIA, MILITIA, SWORDSMAN, GUARD, ARCHER, ARCHER], GameManager.champion)
	_unlock_notice = UNLOCK_NOTICE.new()
	$Screen.add_child(_unlock_notice)
	GameManager.monster_unlocked.connect(_unlock_notice.enqueue)
	_bestiary = BESTIARY_OVERLAY.new()
	$Screen.add_child(_bestiary)
	_bestiary.closed.connect(_on_bestiary_closed)
	$Screen/Bestiary.pressed.connect(_open_bestiary)
	_rebuild_hand()
	_battle.changed.connect(_update_battle)
	$Screen/NewRun.pressed.connect(_new_run)
	_update_focus_command_ui()

func _build_focus_command_ui() -> void:
	_focus_panel = Panel.new()
	_focus_panel.position = Vector2(18, 318)
	_focus_panel.size = Vector2(300, 112)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.06, 0.055, 0.9)
	style.set_border_width_all(2)
	style.border_color = Color(0.38, 0.39, 0.35)
	_focus_panel.add_theme_stylebox_override("panel", style)
	$Screen.add_child(_focus_panel)
	var title := Label.new()
	title.text = "DIVINE COMMANDS"
	title.position = Vector2(12, 8)
	title.size = Vector2(276, 24)
	title.add_theme_font_size_override("font_size", 17)
	_focus_panel.add_child(title)
	_focus_button = Button.new()
	_focus_button.position = Vector2(12, 42)
	_focus_button.size = Vector2(276, 54)
	_focus_button.add_theme_font_size_override("font_size", 18)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var button_style := StyleBoxFlat.new()
		button_style.bg_color = Color(0.22, 0.22, 0.22) if state == "hover" else Color(0.08, 0.08, 0.08)
		button_style.set_border_width_all(2)
		button_style.border_color = Color(0.7, 0.7, 0.7)
		_focus_button.add_theme_stylebox_override(state, button_style)
	_focus_button.pressed.connect(_begin_focus_selection)
	_focus_panel.add_child(_focus_button)

func _update_power(value: float) -> void:
	_power_label.text = "Divine Power: %d / 10" % floori(value)

func _unhandled_input(event: InputEvent) -> void:
	if not _focus_selecting:
		return
	if event.is_action_pressed("ui_cancel"):
		_cancel_focus_selection()
		get_viewport().set_input_as_handled()
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var target := _enemy_at_viewport_position(mouse_event.position)
	if target != null and GameManager.start_focus_target(target):
		_focus_selecting = false
		_focus_marker.bind(target)
	else:
		_focus_selecting = false
	_update_focus_command_ui()
	get_viewport().set_input_as_handled()

func _begin_focus_selection() -> void:
	if _focus_selecting:
		_cancel_focus_selection()
		return
	if not _battle.is_combat_active() or not GameManager.is_focus_ready():
		return
	_focus_selecting = true
	_update_focus_command_ui()

func _cancel_focus_selection() -> void:
	_focus_selecting = false
	_update_focus_command_ui()

func _enemy_at_viewport_position(viewport_position: Vector2) -> Unit:
	var world_position: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * viewport_position
	var best: Unit = null
	var best_distance_squared: float = INF
	for node: Node in get_tree().get_nodes_in_group("units"):
		var unit: Unit = node as Unit
		if unit == null or not _arena.is_ancestor_of(unit) or not GameManager.is_valid_focus_target(unit):
			continue
		var radius: float = maxf(44.0, 34.0 + unit.engagement_body_radius)
		var distance_squared: float = unit.global_position.distance_squared_to(world_position)
		if distance_squared <= radius * radius and distance_squared < best_distance_squared:
			best = unit
			best_distance_squared = distance_squared
	return best

func _update_focus_command_ui() -> void:
	if not is_instance_valid(_focus_button):
		return
	if _focus_selecting:
		_focus_button.text = "SELECT ENEMY..."
	elif GameManager.focus_cooldown_remaining > 0.0:
		_focus_button.text = "FOCUS TARGET (%.1f)" % GameManager.focus_cooldown_remaining
	else:
		_focus_button.text = "FOCUS TARGET"
	_focus_button.disabled = not _battle.is_combat_active() or GameManager.focus_cooldown_remaining > 0.0
	if is_instance_valid(_focus_marker) and GameManager.get_focus_target() == null:
		_focus_marker.hide()

func _on_dragging_changed(active: bool) -> void:
	_region.visible = active and not _cards_locked()

func _rebuild_hand() -> void:
	for child: Node in _hand.get_children():
		_hand.remove_child(child)
		child.queue_free()
	for slot: int in range(deck.hand.size()):
		var card: SummonCard = CARD_SCENE.instantiate()
		card.card_id = deck.hand[slot]
		card.data = deck.definitions[card.card_id]
		card.is_champion = deck.is_champion(card.card_id)
		card.champion = deck.champion
		card.upgrade_level = deck.get_upgrade_level(card.card_id)
		card.position = Vector2(float(slot) * 336.0 - (float(deck.hand.size()) * 336.0 - 16.0) / 2.0, 0)
		_hand.add_child(card)
		card.set_interaction_locked(_cards_locked())
		card.dragging_changed.connect(_on_dragging_changed)
		card.dropped.connect(_on_card_dropped)
	$Screen/Piles.text = "Draw: %d\nDiscard: %d" % [deck.draw_pile.size(), deck.discard_pile.size()]

func _on_card_dropped(card: SummonCard, viewport_position: Vector2) -> void:
	if _cards_locked() or card.consumed or not deck.hand.has(card.card_id):
		return
	var data: CardData = deck.definitions[card.card_id]
	if _region.try_summon(data.unit_scene, viewport_position, data.divine_power_cost, data, deck.get_upgrade_level(card.card_id), deck.champion, card.card_id) == null:
		return
	deck.play(card.card_id)
	# Finish the input callback before replacing its UI nodes.
	for child: SummonCard in _hand.get_children():
		child.consume()
	_rebuild_hand.call_deferred()


func _update_battle() -> void:
	var definition: BattleDefinition = _battle.current_definition()
	if definition == null:
		return
	$Screen/BattleStatus.text = "BATTLE %d/%d\n%s\nEnemies: %d" % [_battle.current_battle, _battle.route.size(), definition.type_label(), _battle.active_enemies.size()]
	$Screen/BattleMessage.text = definition.special_label if _battle.is_combat_active() else ""
	var normal_reward: bool = _battle.phase == BattleManager.Phase.REWARD and definition.reward_type == BattleDefinition.RewardType.NORMAL
	var elite_reward: bool = _battle.phase == BattleManager.Phase.REWARD and definition.reward_type == BattleDefinition.RewardType.ELITE
	if normal_reward:
		if _reward_battle != _battle.current_battle:
			_reward_battle = _battle.current_battle
			_reward_cards = CardCatalog.draw_offers(GameManager.get_eligible_cards(), 2)
			_reward.open(_reward_cards)
	else:
		_reward.hide()
	if elite_reward:
		if _elite_reward_battle != _battle.current_battle:
			_elite_reward_battle = _battle.current_battle
			_elite_relic_offers = GameManager.draw_relic_offers(3)
			if _elite_relic_offers.is_empty():
				_battle.claim_reward(BattleDefinition.RewardType.ELITE)
				_battle.continue_after_reward()
			else:
				_elite_reward.open(_elite_relic_offers)
	else:
		_elite_reward.hide()
	if _battle.shop_open and _shop_visit != _battle.shop_visit:
		_shop_visit = _battle.shop_visit
		_purchased.fill(false)
		_shop.close_selection()
		_shop_cards = CardCatalog.draw_offers(GameManager.get_eligible_cards(), 3)
		_shop.configure_offers(_shop_cards)
	_shop.visible = _battle.shop_open
	$Screen/VictoryShade.visible = _battle.victory
	$Screen/BossMessage.visible = _battle.victory
	$Screen/BossMessage.text = "VICTORY\nTHE HOLLOW KING HAS FALLEN\nRUN COMPLETE"
	if definition.type == BattleDefinition.BattleType.BOSS:
		for enemy: Unit in _battle.active_enemies:
			if enemy is HollowKing and not enemy.is_dead:
				_boss_ui.bind_boss(enemy)
	$Screen/NewRun.visible = _battle.victory
	$Screen/Bestiary.disabled = not _can_open_bestiary()
	_refresh_shop()
	for card: SummonCard in _hand.get_children():
		card.set_interaction_locked(_cards_locked())
	if _cards_locked():
		_region.hide()
	if not _battle.is_combat_active() and _focus_selecting:
		_focus_selecting = false
	_update_focus_command_ui()

func _choose_elite_relic(id: StringName) -> void:
	if not _battle.claim_reward(BattleDefinition.RewardType.ELITE):
		return
	if not GameManager.add_relic(id):
		return
	_elite_reward.hide()
	_battle.continue_after_reward()

func _update_gold(value: int) -> void:
	$Screen/Gold.text = "Gold: %d" % value
	_refresh_shop()

func _choose_reward(index: int) -> void:
	if index < 0 or index > 2 or (index < 2 and index >= _reward_cards.size()) or not _battle.claim_reward():
		return
	if index == 2:
		GameManager.add_gold(75)
	else:
		deck.add_reward(_reward_cards[index])
	$Screen/Piles.text = "Draw: %d\nDiscard: %d" % [deck.draw_pile.size(),deck.discard_pile.size()]
	_reward.mark_selected(index)

func _continue_reward() -> void:
	_battle.continue_after_reward()

func _refresh_shop() -> void:
	if is_instance_valid(_hand):
		for card: SummonCard in _hand.get_children():
			card.refresh_presentation()
	if is_instance_valid(_shop):
		_shop.refresh(GameManager.gold, _purchased, deck.get_all_logical_cards().size(), deck.has_upgradeable_cards())
		_shop.refresh_training(GameManager.champion, GameManager.gold)

func _buy_card(index: int) -> void:
	if not _battle.shop_open or _shop.selecting or index < 0 or index >= _shop_cards.size() or _purchased[index]:
		return
	if not GameManager.try_spend_gold(CardCatalog.shop_price(_shop_cards[index])):
		return
	_purchased[index] = true
	deck.add_card(_shop_cards[index])
	_rebuild_hand()
	_refresh_shop()

func _open_removal() -> void:
	if _battle.shop_open and GameManager.gold >= 50 and deck.get_all_logical_cards().size() > 3:
		_shop.open_selection(_selection_captions(false))

func _remove_card(id: int) -> void:
	if not _battle.shop_open or not _shop.selecting or _shop.selection_mode != "remove" or GameManager.gold < 50:
		return
	if not deck.remove_card_by_id(id):
		return
	GameManager.try_spend_gold(50)
	_shop.close_selection()
	_rebuild_hand()
	_refresh_shop()

func _selection_captions(upgrade_only: bool) -> Dictionary:
	var captions: Dictionary = {}
	for id: int in deck.get_all_logical_cards():
		if (upgrade_only and deck.can_upgrade(id)) or (not upgrade_only and not deck.is_champion(id)):
			captions[id] = deck.card_caption(id)
			if upgrade_only:
				var level: int = deck.get_upgrade_level(id)
				captions[id] += "\nCurrent: " + UnitCardFace.stat_caption(deck.definitions[id], level, deck.champion, id)
				captions[id] += "   →   Next: " + UnitCardFace.stat_caption(deck.definitions[id], level + 1, deck.champion, id)
	return captions

func _open_upgrade() -> void:
	if _battle.shop_open and GameManager.gold >= UPGRADE_COST and deck.has_upgradeable_cards():
		_shop.open_selection(_selection_captions(true), "upgrade")

func _upgrade_card(id: int) -> void:
	if not _battle.shop_open or not _shop.selecting or _shop.selection_mode != "upgrade" or GameManager.gold < UPGRADE_COST:
		return
	if not deck.upgrade_card(id):
		return
	GameManager.try_spend_gold(UPGRADE_COST)
	_shop.close_selection()
	_rebuild_hand()
	_refresh_shop()

func _open_training() -> void:
	if _battle.shop_open:
		_shop.open_training(GameManager.champion, GameManager.gold)

func _learn_skill(skill_id: StringName) -> void:
	if _battle.shop_open and _shop.selecting and _shop.selection_mode == "training":
		GameManager.try_learn_champion_skill(skill_id)


func _new_run() -> void:
	if not _battle.victory or _restarting or _bestiary.visible or get_tree().paused:
		return
	_restarting = true
	$Screen/NewRun.disabled = true
	_restart_scene.call_deferred()

func _restart_scene() -> void:
	# Scene replacement frees old units, deck, overlays and their signal connections.
	# The GameManager autoload (and its permanent unlock registry) survives.
	var result: Error = get_tree().reload_current_scene()
	if result != OK:
		_restarting = false
		$Screen/NewRun.disabled = false
		push_error("Could not start a new run: %s" % error_string(result))


func _cards_locked() -> bool:
	return get_tree().paused or _focus_selecting or not _battle.is_combat_active() or (is_instance_valid(_bestiary) and _bestiary.visible)

func _can_open_bestiary() -> bool:
	return not _restarting and _battle.current_battle > 0 and not _battle.between_battles and not _battle.shop_open and not _reward.visible and not _elite_reward.visible and not _shop.visible and not _shop.selecting

func _open_bestiary() -> void:
	if not _can_open_bestiary() or _bestiary.visible:
		return
	_bestiary.open()
	for card: SummonCard in _hand.get_children():
		card.set_interaction_locked(true)
	_region.hide()

func _on_bestiary_closed() -> void:
	for card: SummonCard in _hand.get_children():
		card.set_interaction_locked(_cards_locked())
	$Screen/Bestiary.disabled = not _can_open_bestiary()
