extends Control
## Presentation only: the controller validates transactions against the deck.
signal purchase_requested(index: int)
signal removal_requested
signal card_removal_requested(id: int)
signal leave_requested
var offers: Array[Button] = []
var gold_label: Label
var remove_button: Button
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
	panel.position = Vector2(-440, -280)
	panel.size = Vector2(880, 560)
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
	for index: int in range(3):
		var button := _button(["Arena Swordsman\nCost: 60 Gold", "Shield Guard\nCost: 90 Gold", "Arena Archer\nCost: 80 Gold"][index], shop)
		button.pressed.connect(func() -> void: purchase_requested.emit(index))
		offers.append(button)
	remove_button = _button("Remove a Card — 50 Gold", shop)
	remove_button.pressed.connect(func() -> void: removal_requested.emit())
	_button("Leave Shop", shop).pressed.connect(func() -> void: leave_requested.emit())
	selection = VBoxContainer.new()
	panel.add_child(selection)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 300
	selection.add_child(scroll)
	card_list = VBoxContainer.new()
	card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(card_list)
	_button("Cancel", selection).pressed.connect(close_selection)
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

func refresh(gold: int, purchased: Array[bool], deck_size: int) -> void:
	gold_label.text = "Gold: %d" % gold
	for index: int in range(3):
		offers[index].disabled = purchased[index] or gold < [60, 90, 80][index]
	remove_button.disabled = gold < 50 or deck_size <= 3

func open_selection(cards: Dictionary) -> void:
	for child: Node in card_list.get_children():
		card_list.remove_child(child)
		child.queue_free()
	for id: int in cards:
		var button := _button(cards[id].display_name, card_list)
		button.pressed.connect(func() -> void: card_removal_requested.emit(id))
	selecting = true
	shop.hide()
	selection.show()

func close_selection() -> void:
	selecting = false
	selection.hide()
	shop.show()
