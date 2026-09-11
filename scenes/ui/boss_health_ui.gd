extends Control
## Non-modal boss status and short phase cues; the boss owns all gameplay state.
var boss: HollowKing
var health: ProgressBar
var phase_label: Label
var cue: Label
var cue_left: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	offset_left = -330
	offset_right = 330
	offset_top = 12
	offset_bottom = 222
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.size = Vector2(660, 110)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var title := Label.new()
	title.text = "THE HOLLOW KING"
	title.tooltip_text = "Ancient Coliseum Tyrant"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	health = ProgressBar.new()
	health.custom_minimum_size.y = 24
	health.show_percentage = false
	health.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for kind: String in ["background", "fill"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.95, 0.95, 0.95) if kind == "fill" else Color(0.05, 0.05, 0.05)
		style.set_border_width_all(2)
		style.border_color = Color(0.5, 0.5, 0.5)
		health.add_theme_stylebox_override(kind, style)
	box.add_child(health)
	phase_label = Label.new()
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.add_theme_font_size_override("font_size", 20)
	box.add_child(phase_label)
	cue = Label.new()
	cue.position = Vector2(0, 120)
	cue.size = Vector2(660, 76)
	cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cue.add_theme_font_size_override("font_size", 25)
	cue.add_theme_color_override("font_outline_color", Color.BLACK)
	cue.add_theme_constant_override("outline_size", 6)
	cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cue)
	hide()

func bind_boss(unit: HollowKing) -> void:
	if boss == unit:
		return
	boss = unit
	boss.health_changed.connect(_health_changed)
	boss.phase_changed.connect(_phase_changed)
	boss.died.connect(_on_death)
	_health_changed(boss.current_health, boss.max_health)
	_update_phase()
	show()

func _health_changed(current: int, maximum: int) -> void:
	health.max_value = maximum
	health.value = current
	_update_phase()

func _update_phase() -> void:
	if is_instance_valid(boss):
		phase_label.text = "PHASE %s  |  %d / %d" % [["I", "II", "III"][boss.phases.phase - 1], boss.current_health, boss.max_health]

func _phase_changed(number: int) -> void:
	_update_phase()
	cue.text = "PHASE II\nCALL OF THE HOLLOW" if number == 2 else "PHASE III\nBROKEN CROWN"
	cue_left = 1.6
	cue.show()

func _process(delta: float) -> void:
	if cue_left > 0:
		cue_left -= delta
		if cue_left <= 0:
			cue.hide()

func _on_death(_unit: Unit) -> void:
	cue_left = 0.0
	cue.hide()
	hide()
