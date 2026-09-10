extends Control
## Read-only view. This overlay alone owns/restores the pause it requested.
signal closed
var entries: Array[VBoxContainer] = []
var close_button: Button
var _was_paused: bool = false
var _opened: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -620
	panel.offset_right = 620
	panel.offset_top = -240
	panel.offset_bottom = 240
	panel.add_theme_stylebox_override("panel", _style(Color(0.06, 0.06, 0.06)))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	panel.add_child(column)
	var title := Label.new()
	title.text = "BESTIARY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	column.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	column.add_child(row)
	for id: StringName in CardCatalog.MONSTER_CARDS:
		var entry_panel := PanelContainer.new()
		entry_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_panel.add_theme_stylebox_override("panel", _style(Color(0.1, 0.1, 0.1)))
		row.add_child(entry_panel)
		var entry := VBoxContainer.new()
		entry.set_meta("monster_id", id)
		entry.custom_minimum_size = Vector2(340, 250)
		entry.add_theme_constant_override("separation", 22)
		entry_panel.add_child(entry)
		var name_label := Label.new()
		name_label.name = "MonsterName"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 26)
		entry.add_child(name_label)
		var detail := Label.new()
		detail.name = "Details"
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail.add_theme_font_size_override("font_size", 22)
		entry.add_child(detail)
		entries.append(entry)
	close_button = Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size.y = 56
	close_button.add_theme_font_size_override("font_size", 24)
	close_button.add_theme_stylebox_override("normal", _style(Color(0.08, 0.08, 0.08)))
	close_button.add_theme_stylebox_override("hover", _style(Color(0.2, 0.2, 0.2)))
	close_button.add_theme_stylebox_override("pressed", _style(Color(0.2, 0.2, 0.2)))
	column.add_child(close_button)
	close_button.pressed.connect(close)
	hide()

func _style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(0.7, 0.7, 0.7)
	style.set_border_width_all(2)
	style.set_content_margin_all(18)
	return style

func open() -> void:
	if _opened:
		return
	var unlocked: Array[StringName] = GameManager.get_unlocked_monster_ids()
	for entry: VBoxContainer in entries:
		var id: StringName = entry.get_meta("monster_id")
		var name_label: Label = entry.get_node("MonsterName")
		var detail: Label = entry.get_node("Details")
		if not unlocked.has(id):
			name_label.text = "???"
			detail.text = "LOCKED"
		else:
			var card: CardData = CardCatalog.MONSTER_CARDS[id]
			name_label.text = card.monster.display_name
			detail.text = "Role: %s\nHP: %d\nDamage: %d\nDivine Power Cost: %d" % [card.monster.role, card.health_by_level[0], card.damage_by_level[0], card.divine_power_cost]
	_was_paused = get_tree().paused
	_opened = true
	show()
	get_tree().paused = true
	close_button.grab_focus()

func close() -> void:
	if not _opened:
		return
	_opened = false
	hide()
	get_tree().paused = _was_paused
	closed.emit()

func _exit_tree() -> void:
	if _opened:
		get_tree().paused = _was_paused
