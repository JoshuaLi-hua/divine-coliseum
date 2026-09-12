extends Control
## Relic reward presentation only; BattleManager owns the single reward claim.

signal relic_chosen(id: StringName)

var _status_label: Label
var _choice_list: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-460, -270)
	panel.size = Vector2(920, 540)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.06, 0.97)
	style.set_border_width_all(2)
	style.border_color = Color(0.7, 0.7, 0.7)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var box := VBoxContainer.new()
	box.position = Vector2(32, 28)
	box.size = Vector2(856, 484)
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title := Label.new()
	title.text = "ELITE REWARD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	box.add_child(title)

	_status_label = Label.new()
	_status_label.text = "Choose a Relic"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 22)
	box.add_child(_status_label)

	_choice_list = VBoxContainer.new()
	_choice_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_choice_list.add_theme_constant_override("separation", 12)
	box.add_child(_choice_list)
	hide()


func open(relics: Array[RelicData]) -> void:
	for child: Node in _choice_list.get_children():
		_choice_list.remove_child(child)
		child.queue_free()
	_status_label.text = "Choose a Relic"
	for relic: RelicData in relics:
		var button := _relic_button(relic)
		button.pressed.connect(_choose_relic.bind(relic.id))
	show()


func _choose_relic(id: StringName) -> void:
	relic_chosen.emit(id)


func _relic_button(relic: RelicData) -> Button:
	var button := Button.new()
	button.text = "%s\n%s" % [relic.display_name, relic.description]
	button.custom_minimum_size.y = 112
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 20)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.24, 0.24, 0.24) if state == "hover" else Color(0.08, 0.08, 0.08)
		style.set_border_width_all(2)
		style.border_color = relic.accent_color if state == "normal" else Color(0.72, 0.72, 0.72)
		button.add_theme_stylebox_override(state, style)
	_choice_list.add_child(button)
	return button
