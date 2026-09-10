extends Control
signal reward_chosen(index: int)
signal continued
var choices: Array[Button] = []
var continue_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0,0,0,0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.position = Vector2(-460,-130)
	box.size = Vector2(920,260)
	box.add_theme_constant_override("separation",24)
	add_child(box)
	var title := Label.new()
	title.text = "CHOOSE A REWARD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",32)
	box.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	box.add_child(row)
	for index: int in range(3):
		var button := Button.new()
		button.text = ["Arena Swordsman Card","Arena Archer Card","+75 Gold"][index]
		button.custom_minimum_size = Vector2(296,100)
		_style(button)
		button.pressed.connect(func() -> void: reward_chosen.emit(index))
		row.add_child(button)
		choices.append(button)
	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size.y = 52
	_style(continue_button)
	continue_button.pressed.connect(func() -> void: continued.emit())
	box.add_child(continue_button)
	hide()

func _style(button: Button) -> void:
	button.add_theme_font_size_override("font_size",22)
	button.add_theme_color_override("font_color",Color.WHITE)
	button.add_theme_color_override("font_disabled_color",Color(0.6,0.6,0.6))
	for state: String in ["normal","hover","pressed","disabled","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12,0.12,0.12) if state != "hover" else Color(0.25,0.25,0.25)
		style.set_border_width_all(2)
		style.border_color = Color(0.7,0.7,0.7)
		button.add_theme_stylebox_override(state,style)

func open() -> void:
	for button: Button in choices:
		button.add_theme_color_override("font_disabled_color",Color(0.6,0.6,0.6))
		button.disabled = false
		button.modulate = Color.WHITE
	continue_button.disabled = true
	show()

func mark_selected(index: int) -> void:
	for i: int in range(choices.size()):
		choices[i].disabled = true
		choices[i].modulate = Color.WHITE if i == index else Color(0.45,0.45,0.45)
	choices[index].add_theme_color_override("font_disabled_color",Color.WHITE)
	continue_button.disabled = false
