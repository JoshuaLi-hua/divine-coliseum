@tool
extends Node2D
## Static Step 1 scenery; replace these drawing layers with real art later.
## Local coordinates are centered under Arena's existing Camera2D.

const COMBAT_RECT: Rect2 = Rect2(-680, -330, 1360, 660)
const WALL_WIDTH: float = 48.0
const STAND_DEPTH: float = 84.0
const BLOCK_LENGTH: float = 80.0
const GATE_SIZE: Vector2 = Vector2(124, 176)
const INK: Color = Color(0.025, 0.025, 0.025)
const BACKGROUND: Color = Color(0.045, 0.045, 0.045)
const STAND: Color = Color(0.13, 0.13, 0.13)
const STONE: Color = Color(0.30, 0.30, 0.30)
const STONE_LIGHT: Color = Color(0.43, 0.43, 0.43)
const FLOOR: Color = Color(0.57, 0.57, 0.57)
const FLOOR_MARK: Color = Color(0.51, 0.51, 0.51)
const PALE: Color = Color(0.80, 0.80, 0.80)


func _draw() -> void:
	# Backing also covers wider windows without changing project settings.
	draw_rect(Rect2(-4096, -4096, 8192, 8192), BACKGROUND)
	_draw_stands()
	_draw_walls()
	_draw_floor()
	for side: float in [-1.0, 1.0]:
		_draw_gate(side)


func _draw_stands() -> void:
	var outer: Rect2 = COMBAT_RECT.grow(WALL_WIDTH + STAND_DEPTH)
	draw_rect(outer.grow(12.0), INK)
	draw_rect(outer, STONE)
	for tier: int in range(3):
		var band: Rect2 = outer.grow(-float(tier) * 26.0 - 8.0)
		draw_rect(band, STAND)
		draw_rect(band, INK, false, 6.0)
		# Paired squares suggest a crowd, leaving regular aisles clear.
		for index: int in range(47):
			var x: float = -754.0 + float(index) * 32.0
			if absf(x) < 55.0 or index % 12 == 0:
				continue
			var shade: Color = STONE if index % 3 == 0 else Color(0.22, 0.22, 0.22)
			for side: float in [-1.0, 1.0]:
				var y: float = side * (band.end.y - 13.0)
				draw_rect(Rect2(x, y - 4.0, 6, 6), shade)
				draw_rect(Rect2(x - 3.0, y + 3.0, 12, 4), shade)
	for x: float in [-544.0, 0.0, 544.0]:
		for side: float in [-1.0, 1.0]:
			var y: float = side * (COMBAT_RECT.end.y + WALL_WIDTH + STAND_DEPTH / 2.0)
			draw_rect(Rect2(x - 10.0, y - 42.0, 20, 84), INK)
			draw_rect(Rect2(x - 4.0, y - 42.0, 8, 84), STONE)


func _draw_walls() -> void:
	var wall: Rect2 = COMBAT_RECT.grow(WALL_WIDTH)
	draw_rect(wall.grow(8.0), INK)
	draw_rect(wall, STONE)
	# Two staggered stone courses; the floor masks their inner edges.
	for course: int in range(2):
		var inset: float = float(course) * 24.0
		for side: float in [-1.0, 1.0]:
			var row_y: float = side * (wall.end.y - inset - 12.0)
			draw_line(Vector2(wall.position.x, row_y + 11.0), Vector2(wall.end.x, row_y + 11.0), INK, 4.0)
			for index: int in range(18):
				var block_x: float = wall.position.x + 24.0 + float(index) * BLOCK_LENGTH + float(course) * 32.0
				draw_line(Vector2(block_x, row_y - 10.0), Vector2(block_x, row_y + 10.0), INK, 4.0)
				draw_line(Vector2(block_x + 7.0, row_y - 7.0), Vector2(block_x + 49.0, row_y - 7.0), STONE_LIGHT, 3.0)
			var column_x: float = side * (wall.end.x - inset - 12.0)
			draw_line(Vector2(column_x + 11.0, wall.position.y), Vector2(column_x + 11.0, wall.end.y), INK, 4.0)
			for block: int in range(-4, 5):
				var block_y: float = float(block) * 76.0 + float(course) * 24.0
				draw_line(Vector2(column_x - 10.0, block_y), Vector2(column_x + 10.0, block_y), INK, 4.0)
	# Corner buttresses give the silhouette architectural weight.
	for x: float in [-wall.end.x, wall.end.x]:
		for y: float in [-wall.end.y, wall.end.y]:
			draw_rect(Rect2(x - 27.0, y - 27.0, 54, 54), INK)
			draw_rect(Rect2(x - 20.0, y - 20.0, 40, 40), STONE_LIGHT)
			draw_rect(Rect2(x - 13.0, y - 13.0, 26, 26), STONE)


func _draw_floor() -> void:
	draw_rect(COMBAT_RECT.grow(8.0), INK)
	draw_rect(COMBAT_RECT, FLOOR)
	draw_rect(COMBAT_RECT.grow(-4.0), PALE, false, 4.0)
	draw_rect(COMBAT_RECT.grow(-16.0), FLOOR_MARK, false, 2.0)
	# Fixed integer formulas: identical markings on every run, no random state.
	for index: int in range(160):
		var x: float = -636.0 + float((index * 173 + 19) % 1260)
		var y: float = -286.0 + float((index * 97 + 43) % 570)
		var length: float = float(4 + (index * 7) % 19)
		draw_rect(Rect2(x, y, length, 2), FLOOR_MARK)
		if index % 5 == 0:
			draw_rect(Rect2(x + length - 2.0, y - 4.0, 2, 4), FLOOR_MARK)
	# Faded angular seal stays low contrast for future units.
	var seal: PackedVector2Array = PackedVector2Array([
		Vector2(-96, -40), Vector2(-40, -96), Vector2(40, -96),
		Vector2(96, -40), Vector2(96, 40), Vector2(40, 96),
		Vector2(-40, 96), Vector2(-96, 40), Vector2(-96, -40),
	])
	draw_polyline(seal, FLOOR_MARK, 3.0)
	draw_line(Vector2(-24, 0), Vector2(24, 0), FLOOR_MARK, 3.0)
	draw_line(Vector2(0, -24), Vector2(0, 24), FLOOR_MARK, 3.0)


func _draw_gate(side: float) -> void:
	var center: Vector2 = Vector2(side * (COMBAT_RECT.end.x + WALL_WIDTH / 2.0), 0)
	var tunnel: Rect2 = Rect2(center - GATE_SIZE / 2.0, GATE_SIZE)
	draw_rect(tunnel.grow(12.0), INK)
	draw_rect(tunnel.grow(6.0), STONE_LIGHT)
	draw_rect(tunnel, INK)
	# Stone jambs and lintel frame a static iron portcullis.
	for y: float in [-72.0, -36.0, 0.0, 36.0, 72.0]:
		for edge: float in [-1.0, 1.0]:
			draw_rect(Rect2(center.x + edge * (GATE_SIZE.x / 2.0 + 6.0) - 9.0, y - 14.0, 18, 28), STONE)
	for index: int in range(7):
		var x: float = tunnel.position.x + 14.0 + float(index) * 16.0
		draw_rect(Rect2(x, tunnel.position.y + 8.0, 6, GATE_SIZE.y - 16.0), STONE_LIGHT)
	for y: float in [-52.0, 52.0]:
		draw_rect(Rect2(tunnel.position.x + 8.0, y - 4.0, GATE_SIZE.x - 16.0, 8), STONE)
		draw_rect(Rect2(center.x - 3.0, y - 3.0, 6, 6), PALE)
	draw_rect(Rect2(center.x - 16.0, -GATE_SIZE.y / 2.0 - 17.0, 32, 20), INK)
	draw_rect(Rect2(center.x - 9.0, -GATE_SIZE.y / 2.0 - 13.0, 18, 12), PALE)
