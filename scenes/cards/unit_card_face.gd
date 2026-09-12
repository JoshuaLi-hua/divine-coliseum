class_name UnitCardFace
extends Control
## Passive presentation shared by draggable cards and offer buttons.
## A detached Unit supplies authoritative stats; only its static polygons are drawn.
var stars: Label
var cost: Label
var unit_name_label: Label
var stats: Label
var category: Label
var description_label: Label
var price_label: Label
var _polygons: Array[Dictionary] = []
var _bounds := Rect2()
var _scene: PackedScene
var _portrait_rect := Rect2()
var _has_price: bool = false

static func effective_stats(data: CardData, level: int, champion: ChampionState = null, id: int = -1) -> Vector2i:
	var unit: Unit = data.unit_scene.instantiate()
	unit.team = Unit.Team.PLAYER
	data.apply_summon_stats(unit, level)
	if champion != null:
		champion.apply_summon_bonuses(unit, id, data)
	var result := Vector2i(unit.attack_damage, unit.max_health)
	unit.free()
	return result

static func star_text(level: int) -> String:
	var current := clampi(level, 1, 3)
	return "★".repeat(current) + "☆".repeat(3 - current)

static func stat_caption(data: CardData, level: int, champion: ChampionState = null, id: int = -1) -> String:
	var values := effective_stats(data, level, champion, id)
	return "%s  ATK %d / HP %d" % [star_text(level), values.x, values.y]

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	stars = _label("StarsRow", 25, HORIZONTAL_ALIGNMENT_LEFT)
	cost = _label("CostBadge", 28)
	cost.tooltip_text = "Divine Power cost"
	unit_name_label = _label("NameLabel", 23)
	stats = _label("StatsRow", 22)
	category = _label("TypeRow", 18)
	description_label = _label("DescriptionLabel", 17)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
	price_label = _label("ShopPrice", 23)
	resized.connect(_layout)
	description_label.minimum_size_changed.connect(_layout.call_deferred)

func _label(node_name: String, font_size: int, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.name = node_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.93, 0.93, 0.93))
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)
	return label

func configure(data: CardData, level: int = 1, champion: ChampionState = null, id: int = -1, price: int = -1) -> void:
	stars.text = star_text(level)
	cost.text = str(data.divine_power_cost)
	unit_name_label.text = data.display_name
	# Keep the longest name on one readable line without reducing every card's font.
	unit_name_label.add_theme_font_size_override("font_size", 21 if data.display_name.length() > 18 else 23)
	var values := effective_stats(data, level, champion, id)
	stats.text = "⚔ %d ATK     ♥ %d HP" % [values.x, values.y]
	category.text = data.unit_type.to_upper()
	description_label.text = data.description
	_has_price = price >= 0
	price_label.text = "%d GOLD" % price if _has_price else ""
	price_label.visible = _has_price
	if _scene != data.unit_scene:
		_scene = data.unit_scene
		_polygons.clear()
		var unit: Unit = _scene.instantiate()
		var visual := unit.get_node("Visual") as Node2D
		_capture(visual, Transform2D.IDENTITY)
		unit.free()
	_layout()

func _capture(node: Node2D, parent_transform: Transform2D) -> void:
	var transform := parent_transform * node.transform
	if node is Polygon2D and node.visible:
		var points: PackedVector2Array = transform * node.polygon
		_polygons.append({"points": points, "color": node.color})
		for point: Vector2 in points:
			if _polygons.size() == 1 and point == points[0]:
				_bounds = Rect2(point, Vector2.ZERO)
			else:
				_bounds = _bounds.expand(point)
	for child: Node in node.get_children():
		if child is Node2D:
			_capture(child, transform)

func _place(label: Label, rect: Rect2) -> void:
	label.position = rect.position
	label.size = rect.size

func _layout() -> void:
	if size.x < 100 or size.y < 200:
		return
	var width := size.x
	var content_bottom := size.y - (40.0 if _has_price else 0.0)
	var portrait_height := maxf(70.0, content_bottom - 216.0)
	_place(stars, Rect2(16, 8, 150, 38))
	_place(cost, Rect2(width - 60, 8, 44, 44))
	_portrait_rect = Rect2(16, 54, width - 32, portrait_height)
	var y := _portrait_rect.end.y + 3
	_place(unit_name_label, Rect2(8, y, width - 16, 32))
	_place(stats, Rect2(8, y + 34, width - 16, 32))
	_place(category, Rect2(12, y + 70, width - 24, 26))
	_place(description_label, Rect2(18, y + 98, width - 36, 48))
	_place(price_label, Rect2(12, size.y - 38, width - 24, 32))
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ONE * 2, size - Vector2.ONE * 4), Color(0.075, 0.075, 0.075))
	draw_rect(Rect2(Vector2.ONE * 3, size - Vector2.ONE * 6), Color(0.68, 0.68, 0.68), false, 2)
	draw_rect(Rect2(Vector2.ONE * 7, size - Vector2.ONE * 14), Color(0.25, 0.25, 0.25), false, 1)
	draw_circle(Vector2(size.x - 38, 30), 23, Color(0.18, 0.18, 0.18))
	draw_arc(Vector2(size.x - 38, 30), 23, 0, TAU, 48, Color(0.85, 0.85, 0.85), 2, true)
	draw_rect(_portrait_rect, Color(0.16, 0.16, 0.16))
	draw_rect(_portrait_rect, Color(0.35, 0.35, 0.35), false, 1)
	if not _polygons.is_empty() and _bounds.size.x > 0 and _bounds.size.y > 0:
		var fit := minf((_portrait_rect.size.x - 20) / _bounds.size.x, (_portrait_rect.size.y - 12) / _bounds.size.y)
		var offset := _portrait_rect.get_center() - _bounds.get_center() * fit
		for polygon: Dictionary in _polygons:
			var points: PackedVector2Array = polygon.points.duplicate()
			for i: int in range(points.size()):
				points[i] = points[i] * fit + offset
			draw_colored_polygon(points, polygon.color)
	var line_y := category.position.y - 2
	draw_line(Vector2(22, line_y), Vector2(size.x - 22, line_y), Color(0.35, 0.35, 0.35))
	if _has_price:
		draw_line(Vector2(22, size.y - 41), Vector2(size.x - 22, size.y - 41), Color(0.55, 0.55, 0.55))
