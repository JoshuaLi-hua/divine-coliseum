extends Control
## Presentation only: the controller validates transactions against the deck.
signal purchase_requested(index: int)
signal removal_requested
signal card_removal_requested(id: int)
signal upgrade_requested
signal card_upgrade_requested(id: int)
signal training_requested
signal skill_requested(id: StringName)
signal leave_requested
var offers: Array[Button] = []
var _offer_prices: Array[int] = []
var gold_label: Label
var remove_button: Button
var upgrade_button: Button
var training_button: Button
var selection_title: Label
var back_button: Button
var selection_mode: String = ""
var shop: VBoxContainer
var selection: VBoxContainer
var card_list: VBoxContainer
var selecting: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := VBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-496, -370)
	panel.size = Vector2(992, 740)
	panel.add_theme_constant_override("separation", 14)
	add_child(panel)
	var title := Label.new()
	title.text = "SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	panel.add_child(title)
	gold_label = Label.new()
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 26)
	panel.add_child(gold_label)
	shop = VBoxContainer.new()
	panel.add_child(shop)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	shop.add_child(row)
	for index: int in range(3):
		var button := _button("", row)
		button.custom_minimum_size = Vector2(320, 378)
		var face := UnitCardFace.new()
		face.name = "CardFace"
		button.add_child(face)
		face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.pressed.connect(func() -> void: purchase_requested.emit(index))
		offers.append(button)
	remove_button = _button("Remove a Card — 50 Gold", shop)
	remove_button.pressed.connect(func() -> void: removal_requested.emit())
	upgrade_button = _button("Upgrade a Card — 75 Gold", shop)
	upgrade_button.pressed.connect(func() -> void: upgrade_requested.emit())
	training_button = _button("Champion Training\nCost depends on selected skill", shop)
	training_button.pressed.connect(func() -> void: training_requested.emit())
	_button("Leave Shop", shop).pressed.connect(func() -> void: leave_requested.emit())
	selection = VBoxContainer.new()
	panel.add_child(selection)
	selection_title = Label.new()
	selection_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selection_title.add_theme_font_size_override("font_size", 26)
	selection.add_child(selection_title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 300
	selection.add_child(scroll)
	card_list = VBoxContainer.new()
	card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(card_list)
	back_button = _button("Cancel", selection)
	back_button.pressed.connect(close_selection)
	close_selection()
	hide()

func _button(caption: String, parent: Node) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 60
	button.add_theme_font_size_override("font_size", 22)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.16, 0.16, 0.16) if state == "hover" else Color(0.05, 0.05, 0.05)
		style.border_color = Color.GRAY
		style.set_border_width_all(2)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	parent.add_child(button)
	return button

func configure_offers(cards: Array[CardData]) -> void:
	assert(cards.size() == offers.size())
	_offer_prices.clear()
	for index: int in range(cards.size()):
		var price: int = CardCatalog.shop_price(cards[index])
		_offer_prices.append(price)
		offers[index].get_node("CardFace").configure(cards[index], 1, null, -1, price)

func refresh(gold: int, purchased: Array[bool], deck_size: int, can_upgrade: bool = false) -> void:
	gold_label.text = "Gold: %d" % gold
	for index: int in range(3):
		offers[index].disabled = index >= _offer_prices.size() or purchased[index] or gold < _offer_prices[index]
		offers[index].modulate = Color(0.5, 0.5, 0.5) if offers[index].disabled else Color.WHITE
	remove_button.disabled = gold < 50 or deck_size <= 3
	upgrade_button.disabled = gold < 75 or not can_upgrade

func open_selection(cards: Dictionary, mode: String = "remove") -> void:
	selection_title.hide()
	back_button.text = "Cancel"
	selection_mode = mode
	for child: Node in card_list.get_children():
		card_list.remove_child(child)
		child.queue_free()
	for id: int in cards:
		var button := _button(str(cards[id]), card_list)
		button.pressed.connect(func() -> void:
			if selection_mode == "upgrade":
				card_upgrade_requested.emit(id)
			else:
				card_removal_requested.emit(id)
		)
	selecting = true
	shop.hide()
	selection.show()

func close_selection() -> void:
	selecting = false
	selection_mode = ""
	selection.hide()
	shop.show()

func open_training(champion: ChampionState, gold: int) -> void:
	open_selection({}, "training")
	selection_title.text = champion.selected.display_name.to_upper()
	selection_title.show()
	back_button.text = "Back"
	for skill: ChampionSkill in champion.selected.skills:
		var button := _button("", card_list)
		button.set_meta("skill_id", skill.id)
		button.pressed.connect(func() -> void: skill_requested.emit(skill.id))
	refresh_training(champion, gold)

func refresh_training(champion: ChampionState, gold: int) -> void:
	if selection_mode != "training":
		return
	for button: Button in card_list.get_children():
		var skill: ChampionSkill = champion.selected.find_skill(button.get_meta("skill_id"))
		var learned: bool = champion.has_learned(skill.id)
		button.text = skill.display_name + "\n" + skill.description() + "\n" + ("LEARNED" if learned else "Cost: %d Gold" % skill.gold_cost)
		button.disabled = learned or gold < skill.gold_cost
