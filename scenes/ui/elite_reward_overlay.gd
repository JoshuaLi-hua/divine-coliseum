extends Control
## Presentation and selection only; BattleManager owns the single reward claim.
signal gold_chosen
signal upgrade_requested
signal card_chosen(id: int)
signal continued
var selecting: bool = false
var gold_button: Button
var upgrade_button: Button
var continue_button: Button
var status_label: Label
var options: VBoxContainer
var selection: VBoxContainer
var card_list: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.position = Vector2(-420, -260)
	box.size = Vector2(840, 520)
	box.add_theme_constant_override("separation", 18)
	add_child(box)
	var title := Label.new()
	title.text = "ELITE VICTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	box.add_child(title)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 22)
	box.add_child(status_label)
	options = VBoxContainer.new()
	options.add_theme_constant_override("separation", 18)
	box.add_child(options)
	gold_button = _button("+150 Gold", options)
	gold_button.pressed.connect(func() -> void: gold_chosen.emit())
	upgrade_button = _button("Upgrade One Card", options)
	upgrade_button.pressed.connect(func() -> void: upgrade_requested.emit())
	selection = VBoxContainer.new()
	selection.add_theme_constant_override("separation", 12)
	box.add_child(selection)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 240
	selection.add_child(scroll)
	card_list = VBoxContainer.new()
	card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_list.add_theme_constant_override("separation", 8)
	scroll.add_child(card_list)
	_button("Cancel", selection).pressed.connect(_cancel_upgrade)
	continue_button = _button("Continue", box)
	continue_button.pressed.connect(func() -> void: continued.emit())
	hide()

func _button(caption: String, parent: Node) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 54
	button.add_theme_font_size_override("font_size", 22)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.24, 0.24, 0.24) if state == "hover" else Color(0.08, 0.08, 0.08)
		style.set_border_width_all(2)
		style.border_color = Color(0.7, 0.7, 0.7)
		button.add_theme_stylebox_override(state, style)
	parent.add_child(button)
	return button

func open(can_upgrade: bool) -> void:
	selecting = false
	selection.hide()
	options.show()
	gold_button.disabled = false
	upgrade_button.disabled = not can_upgrade
	upgrade_button.tooltip_text = "All cards are already at maximum stars." if not can_upgrade else ""
	status_label.text = "Choose one reward" if can_upgrade else "Choose one reward — no cards available to upgrade"
	continue_button.disabled = true
	show()

func open_upgrade(captions: Dictionary) -> void:
	for child: Node in card_list.get_children():
		card_list.remove_child(child)
		child.queue_free()
	for id: int in captions:
		_button(captions[id], card_list).pressed.connect(func() -> void: card_chosen.emit(id))
	selecting = true
	options.hide()
	selection.show()
	status_label.text = "Choose a card to gain one star"

func _cancel_upgrade() -> void:
	selecting = false
	selection.hide()
	options.show()
	status_label.text = "Choose one reward"

func mark_selected(caption: String) -> void:
	selecting = false
	selection.hide()
	options.show()
	gold_button.disabled = true
	upgrade_button.disabled = true
	status_label.text = caption
	continue_button.disabled = false
