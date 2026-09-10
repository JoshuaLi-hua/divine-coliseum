extends PanelContainer
## Non-modal FIFO notification: simultaneous first kills each get screen time.
var _pending: Array[MonsterData] = []
var _remaining: float = 0.0
var _label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -440
	offset_top = 128
	offset_right = -24
	offset_bottom = 210
	custom_minimum_size = Vector2(416, 82)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.06, 0.94)
	style.border_color = Color(0.8, 0.8, 0.8)
	style.set_border_width_all(2)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 20)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	hide()

func enqueue(data: MonsterData) -> void:
	_pending.append(data)
	if _remaining <= 0.0:
		_show_next()

func _process(delta: float) -> void:
	if _remaining > 0.0:
		_remaining -= delta
		if _remaining <= 0.0:
			_show_next()

func _show_next() -> void:
	if _pending.is_empty():
		hide()
		return
	var data: MonsterData = _pending.pop_front()
	_label.text = "MONSTER CARD UNLOCKED\n" + data.display_name
	_remaining = 2.5
	show()
