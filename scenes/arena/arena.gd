@tool
extends Node2D
## Draws only the placeholder arena; no gameplay behavior.

const COMBAT_RECT: Rect2 = Rect2(-720.0, -380.0, 1440.0, 760.0)
const WALL_WIDTH: float = 32.0
const WALL_COLOR: Color = Color(0.24, 0.24, 0.24)
const FLOOR_COLOR: Color = Color(0.12, 0.12, 0.12)
const BORDER_COLOR: Color = Color(0.65, 0.65, 0.65)


func _draw() -> void:
	draw_rect(COMBAT_RECT.grow(WALL_WIDTH + 6.0), Color.BLACK)
	draw_rect(COMBAT_RECT.grow(WALL_WIDTH), WALL_COLOR)
	draw_rect(COMBAT_RECT, FLOOR_COLOR)
	draw_rect(COMBAT_RECT, BORDER_COLOR, false, 4.0)
