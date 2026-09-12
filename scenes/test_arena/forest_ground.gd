@tool
extends Node2D
## Deterministic lightweight scenery; no random-number or progression state.
const CLEARING := Rect2(-680, -330, 1360, 660)
const SUMMON_RECT := Rect2(-620, -240, 540, 510)
var highlight_summon: bool = false:
	set(value):
		highlight_summon = value
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-4096, -4096, 8192, 8192), Color(0.065, 0.069, 0.066))
	for row: int in range(3):
		for i: int in range(21):
			var x := -870.0 + i * 87.0 + row * 21.0
			_tree(Vector2(x, -340 - row * 52), 0.8 + (i % 4) * 0.15, 0.12 + row * 0.025)
	for side: float in [-1, 1]:
		for i: int in range(6):
			_tree(Vector2(side * (740 + (i % 2) * 35), -210 + i * 110), 1.2, 0.16)
	draw_rect(CLEARING.grow(10), Color(0.17, 0.17, 0.15))
	draw_rect(CLEARING, Color(0.36, 0.36, 0.32))
	draw_rect(CLEARING.grow(-10), Color(0.43, 0.43, 0.38), false, 2)
	for i: int in range(120):
		var point := Vector2(-650 + (i * 173) % 1300, -308 + (i * 97) % 615)
		draw_line(point, point + Vector2(7 + i % 11, -2), Color(0.31, 0.32, 0.28), 2)
	# Broken stone footings frame the clearing, outside usable combat bounds.
	for side: float in [-1, 1]:
		for i: int in range(7):
			var rect := Rect2(-530 + i * 170, side * 355 - 15, 62 + i % 3 * 13, 24)
			draw_rect(rect.grow(3), Color(0.12, 0.13, 0.12))
			draw_rect(rect, Color(0.39, 0.4, 0.37))
			draw_line(rect.position + Vector2(3, 3), rect.position + Vector2(rect.size.x - 6, 3), Color(0.56, 0.56, 0.51), 2)
	draw_rect(SUMMON_RECT, Color(0.8, 0.8, 0.7, 0.13 if highlight_summon else 0.035))
	draw_rect(SUMMON_RECT, Color(0.8, 0.8, 0.7, 0.9 if highlight_summon else 0.3), false, 2)
	draw_arc(Vector2(340, 0), 80, 0, TAU, 48, Color(0.57, 0.56, 0.49), 2, true)
	draw_line(Vector2(0, -300), Vector2(0, 300), Color(0.43, 0.43, 0.38), 1)

func _tree(point: Vector2, scale_factor: float, shade: float) -> void:
	draw_rect(Rect2(point + Vector2(-5, -115) * scale_factor, Vector2(10, 115) * scale_factor), Color(shade, shade, shade * 0.9))
	for tier: int in range(3):
		var top := point + Vector2(0, -165 + tier * 35) * scale_factor
		var width := (35 + tier * 13) * scale_factor
		draw_colored_polygon(PackedVector2Array([top, top + Vector2(width, 70 * scale_factor), top + Vector2(-width, 70 * scale_factor)]), Color(shade, shade + 0.01, shade))
