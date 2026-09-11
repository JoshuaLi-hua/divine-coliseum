class_name UnitActionVisual
extends Node2D
## Monochrome placeholder poses only; no damage, targeting, or timer ownership.
# Body preparation, body impact, weapon preparation/impact radians, recoil wobble.
const STRIKES: Dictionary = {
	"knight": [Vector2(3,-1), Vector2(-5,1), -0.08, 0.12, 0.65, -1.30],
	"militia": [Vector2(1,-1), Vector2(-3,1), 0.06, 0.18, 0.32, -0.60],
	"swordsman": [Vector2(1,0), Vector2(-4,-1), -0.13, 0.08, 0.85, -1.15],
	"guard": [Vector2(1,0), Vector2(-3,0), 0.0, 0.025, 0.05, -0.10],
	"archer": [Vector2(3,0), Vector2(1,0), -0.08, 0.04, -0.12, 0.12],
	"healer": [Vector2(0,-3), Vector2(0,-1), 0.0, 0.0, 0.10, -0.10],
	"orc": [Vector2(6,-2), Vector2(-9,3), -0.23, 0.30, 0.95, -1.75],
	"troll": [Vector2(2,-7), Vector2(-5,6), -0.10, 0.19, 0.35, -1.90],
	"spider": [Vector2(2,2), Vector2(-7,-1), 0.0, 0.0, -0.22, 0.34],
	"bonecaller": [Vector2(0,-4), Vector2(2,-1), -0.08, 0.06, 0.32, -0.40],
	"minion": [Vector2(1,1), Vector2(-2,0), -0.05, 0.10, 0.24, -0.44],
}
# Recoil distance, collapse rotation, final height scale, downward sink.
const DEATHS: Dictionary = {
	"knight": Vector4(3,0.22,0.32,9), "militia": Vector4(5,0.80,0.25,6),
	"swordsman": Vector4(8,1.05,0.42,5), "guard": Vector4(1,0.08,0.20,12),
	"archer": Vector4(4,0.65,0.38,8), "healer": Vector4(0,-0.10,0.15,8),
	"orc": Vector4(12,0.72,0.28,10), "troll": Vector4(3,-0.12,0.22,15),
	"spider": Vector4(0,0.0,0.18,4), "bonecaller": Vector4(2,-0.25,0.10,12),
	"minion": Vector4(1,0.18,0.08,7),
}
const PART_PIVOTS: Dictionary = {
	"knight": Vector2(23,-22), "orc": Vector2(24,-25),
	"troll": Vector2(36,-36), "spider": Vector2(0,-16),
}
var ground_position: Vector2
var _visual: Node2D
var _pose: Node2D
var _weapon: Node2D
var _style: String
var _mirror: float = 1.0
var _time: float = 0.0
var _effect: StringName
var _effect_strength: float = 0.0
var _progress: float = 0.0
var _direction: Vector2 = Vector2.LEFT

func setup(visual: Node2D, style: String, parts: PackedStringArray) -> void:
	_visual = visual
	_style = style
	var children: Array[Node] = visual.get_children()
	_pose = Node2D.new()
	_pose.name = "ActionPose"
	visual.add_child(_pose)
	for child: Node in children:
		child.reparent(_pose)
	_weapon = Node2D.new()
	_weapon.name = "ActionParts"
	_weapon.position = PART_PIVOTS.get(style, Vector2(-10,-30))
	_pose.add_child(_weapon)
	for part_name: String in parts:
		var part: Node = _pose.get_node_or_null(NodePath(part_name))
		if part != null:
			part.reparent(_weapon)

func _reset(direction: Vector2) -> void:
	_direction = direction
	# Shape silhouettes face left. Keep Shield Guard's accepted block-facing root.
	_mirror = -1.0 if direction.x * signf(_visual.scale.x) > 0.0 else 1.0
	_pose.position = Vector2.ZERO
	_pose.rotation = 0.0
	_pose.scale = Vector2(_mirror,1)
	_pose.modulate = Color.WHITE
	_weapon.rotation = 0.0
	_weapon.scale = Vector2.ONE
	_weapon.position = PART_PIVOTS.get(_style, Vector2(-10,-30))
	_effect_strength = 0.0

func locomotion(delta: float, moving: bool, direction: Vector2) -> void:
	_reset(direction)
	_time += delta
	if moving:
		_pose.position.y = -absf(sin(_time * (8.0 if _style == "troll" else 13.0))) * (1.0 if _style == "spider" else 1.6)
	queue_redraw()

func pose(kind: StringName, anticipation: float, recovery: float, direction: Vector2) -> void:
	_reset(direction)
	_effect = kind
	_progress = anticipation
	if kind == &"death":
		_death(anticipation)
	elif kind == &"emerge":
		_pose.position.y = lerpf(20,0,anticipation)
		_pose.scale.y = lerpf(0.08,1.0,anticipation)
		_pose.modulate.a = clampf(anticipation * 2.5,0.0,1.0)
		_effect_strength = sin(anticipation * PI)
	elif kind == &"heal" or kind == &"summon":
		_cast(kind, anticipation, recovery)
	else:
		_strike(anticipation, recovery)
	queue_redraw()

func _strike(progress: float, recovery: float) -> void:
	var profile: Array = STRIKES.get(_style, STRIKES["militia"])
	var offset: Vector2
	var rotation_amount: float
	var weapon_rotation: float
	if progress < 0.68:
		var pull: float = smoothstep(0.0,0.68,progress)
		offset = Vector2.ZERO.lerp(profile[0],pull)
		rotation_amount = profile[2] * pull
		weapon_rotation = profile[4] * pull
	else:
		var swing: float = smoothstep(0.68,1.0,progress)
		offset = (profile[0] as Vector2).lerp(profile[1],swing)
		rotation_amount = lerpf(profile[2],profile[3],swing)
		weapon_rotation = lerpf(profile[4],profile[5],swing)
	var settle: float = 1.0 - smoothstep(0.0,1.0,recovery)
	_pose.position = Vector2(offset.x * _mirror,offset.y) * settle
	_pose.rotation = rotation_amount * _mirror * settle
	_weapon.rotation = weapon_rotation * settle
	if _style == "guard":
		_weapon.position.x -= 7.0 * progress * settle
	elif _style == "archer":
		_weapon.scale.x = 1.0 - 0.22 * sin(progress * PI)
		_weapon.position.x += 4.0 * sin(progress * PI)
	elif _style == "spider":
		_pose.scale.y = lerpf(0.83,1.06,progress) if recovery == 0.0 else lerpf(1.06,1.0,recovery)
		_weapon.scale.x = lerpf(0.75,1.22,progress) if recovery == 0.0 else lerpf(1.22,1.0,recovery)
	elif _style == "militia":
		_weapon.rotation += sin(recovery * TAU) * 0.14 * settle
	elif _style == "troll":
		_weapon.position.y -= sin(progress * PI) * 12.0
	if progress >= 1.0:
		_effect_strength = maxf(0.0,1.0-recovery*3.0)

func _cast(kind: StringName, progress: float, recovery: float) -> void:
	var settle: float = 1.0 - recovery
	if kind == &"heal":
		_pose.position.y = -4.0 * sin(progress * PI * 0.5) * settle
		_weapon.position.y -= 9.0 * progress * settle
		_weapon.rotation = 0.12 * sin(progress * PI) * settle
	else:
		_pose.position.y = -7.0 * sin(progress * PI) * settle
		_pose.rotation = lerpf(-0.15,0.20,progress) * _mirror * settle
		_weapon.rotation = lerpf(0.80,-0.85,progress) * settle
		_weapon.position.y -= sin(progress * PI) * 13.0
	_effect_strength = (0.2 + progress * 0.8) * settle

func _death(progress: float) -> void:
	var profile: Vector4 = DEATHS.get(_style, DEATHS["militia"])
	var fall: float = smoothstep(0.22,1.0,progress)
	_pose.position = Vector2(profile.x * sin(minf(1.0,progress*2.0)*PI*0.5)*_mirror, profile.w*fall)
	_pose.rotation = profile.y * fall * _mirror
	_pose.scale.y = lerpf(1.0,profile.z,fall)
	_weapon.rotation = fall * (0.9 if _style == "archer" else 0.3)
	if _style in ["spider","minion","healer"]:
		_pose.scale.x *= lerpf(1.0,0.35,fall)
		_weapon.scale.x = lerpf(1.0,0.3,fall)
	if _style == "troll":
		_pose.position.x += sin(progress*35.0)*(1.0-fall)*2.5
	if _style == "guard": _weapon.position.y += 15.0 * fall
	_pose.modulate.a = 1.0 - smoothstep(0.50,1.0,progress)

func _draw() -> void:
	if _effect_strength <= 0.0:
		return
	var pale: Color = Color(0.94,0.94,0.94,0.65*_effect_strength)
	if _effect in [&"summon", &"emerge", &"heal"]:
		var center: Vector2 = to_local(ground_position) if _effect == &"summon" else Vector2.ZERO
		var radius: float = (44.0 if _effect == &"heal" else 25.0) * (0.65+0.35*_progress)
		var points := PackedVector2Array()
		for index: int in range(33):
			var angle: float = TAU * index / 32.0
			points.append(center+Vector2(cos(angle)*radius,sin(angle)*radius*0.30))
		draw_polyline(points,pale,2.0,true)
		if _effect == &"heal":
			draw_line(Vector2(-5,-62),Vector2(5,-62),pale,2.0)
			draw_line(Vector2(0,-67),Vector2(0,-57),pale,2.0)
	elif _effect == &"attack":
		var side: float = -1.0 if _direction.x < 0 else 1.0
		if _style == "troll":
			draw_line(Vector2(side*18,-3),Vector2(side*44,-3),pale,3.0)
		elif _style == "spider":
			for y: float in [-26.0,-18.0]: draw_line(Vector2(side*20,y),Vector2(side*38,y-3),pale,2.0)
		elif _style == "guard":
			draw_line(Vector2(side*21,-30),Vector2(side*32,-30),pale,2.0)
		else:
			var radius: float = 12.0 if _style == "minion" else (25.0 if _style == "orc" else 19.0)
			var angle: float = PI if side<0 else 0.0
			draw_arc(Vector2(side*13,-30),radius,angle-0.7,angle+0.7,12,pale,2.0,true)
	elif _effect == &"ranged" and _style == "bonecaller":
		draw_circle(Vector2(-22 if _direction.x<0 else 22,-43),5.0,pale)
