class_name RelicHud
extends Panel
## Compact run HUD for currently owned relics.

var _title: Label
var _list: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(300, 150)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.06, 0.055, 0.9)
	style.set_border_width_all(2)
	style.border_color = Color(0.38, 0.39, 0.35)
	add_theme_stylebox_override("panel", style)
	_title = Label.new()
	_title.text = "RELICS"
	_title.position = Vector2(12, 8)
	_title.size = Vector2(276, 26)
	_title.add_theme_font_size_override("font_size", 18)
	add_child(_title)
	_list = Label.new()
	_list.position = Vector2(12, 36)
	_list.size = Vector2(276, 104)
	_list.add_theme_font_size_override("font_size", 15)
	_list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_list)
	GameManager.relics_changed.connect(refresh)
	refresh()

func refresh() -> void:
	if not is_instance_valid(_list):
		return
	var names: PackedStringArray = []
	for relic: RelicData in GameManager.get_owned_relics():
		names.append("• " + relic.display_name)
	_list.text = "None" if names.is_empty() else "\n".join(names)
