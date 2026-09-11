class_name HollowKingVisual
extends UnitActionVisual
## Boss-only child poses and world-space telegraphs; never moves the combat body.
var boss_phase: int = 1
var warning_visible: bool = false
var _crown: Node2D
var _recovery: float = 0.0

func setup(visual: Node2D, style: String, parts: PackedStringArray) -> void:
	super.setup(visual, style, parts)
	_crown = _pose.get_node("Crown")

func _reset(direction: Vector2) -> void:
	super._reset(direction)
	if is_instance_valid(_crown):
		_crown.transform = _bases[_crown]
	warning_visible = false

func pose(kind: StringName, anticipation: float, recovery: float, direction: Vector2) -> void:
	_reset(direction)
	_effect = kind
	_progress = anticipation
	_recovery = recovery
	var settle: float = 1.0 - smoothstep(0.0, 1.0, recovery)
	var swing: float = smoothstep(0.72, 1.0, anticipation)
	match kind:
		&"attack":
			_weapon_rotation = lerpf(0.85 * anticipation, -1.15, swing) * settle
			_body_rotation = lerpf(-0.03, 0.06, swing) * _mirror * settle
			_body_position = Vector2(-7 * swing * _mirror, 4 * swing) * settle
		&"cleave":
			_weapon_rotation = lerpf(1.2 * anticipation, -1.6, swing) * settle
			_body_rotation = lerpf(-0.08 * anticipation, 0.08, swing) * _mirror * settle
			_weapon_scale.x = 1.0 + 0.12 * swing * settle
		&"hollow_summon":
			_weapon_rotation = 0.65 * sin(anticipation * PI) * settle
			_body_position.y = -8 * sin(anticipation * PI) * settle
			_crown.position.y = _bases[_crown].origin.y - 10 * sin(anticipation * PI) * settle
		&"phase_change":
			var strength: float = 1.0 if boss_phase == 2 else 1.8
			_body_rotation = sin(anticipation * TAU * 2) * 0.035 * strength * _mirror
			_crown.position.y = _bases[_crown].origin.y - 18 * sin(anticipation * PI) * strength
			_crown.rotation = _bases[_crown].get_rotation() + sin(anticipation * PI) * 0.08 * strength
			_weapon_rotation = -0.25 * sin(anticipation * PI)
		&"royal_slam":
			warning_visible = anticipation < 1.0
			_weapon_position.y = -24 * anticipation * (1.0 - swing) * settle
			_weapon_rotation = lerpf(0.1, -1.25, swing) * settle
			_body_position.y = lerpf(-9 * anticipation, 12.0, swing) * settle
			_body_scale.y = 1.0 - 0.14 * swing * settle
		&"death":
			var collapse: float = smoothstep(0.25, 1.0, anticipation)
			_body_position = Vector2(12 * sin(anticipation * PI) * _mirror, 22 * collapse)
			_body_rotation = -0.28 * collapse * _mirror
			_body_scale.y = lerpf(1.0, 0.16, collapse)
			_weapon_rotation = -1.4 * collapse
			_crown.position = _bases[_crown].origin + Vector2(24 * collapse, 80 * collapse)
			_crown.rotation = _bases[_crown].get_rotation() + collapse * 0.45
			_body_color.a = 1.0 - smoothstep(0.62, 1.0, anticipation)
	_apply_rig()
	queue_redraw()

func _draw() -> void:
	var pale := Color(0.98, 0.98, 0.98, 0.85)
	if warning_visible:
		draw_circle(Vector2.ZERO, 165, Color(0.02, 0.02, 0.02, 0.18))
		draw_arc(Vector2.ZERO, 165, 0, TAU, 64, Color.BLACK, 7.0, true)
		draw_arc(Vector2.ZERO, 165, 0, TAU, 64, pale, 3.0, true)
		draw_arc(Vector2.ZERO, 165 * _progress, 0, TAU, 64, pale, 2.0, true)
		for index: int in range(8):
			var axis: Vector2 = Vector2.from_angle(index * TAU / 8)
			draw_line(axis * 145, axis * 165, pale, 4.0)
	elif _effect == &"royal_slam" and _progress >= 1.0 and _recovery < 0.5:
		pale.a *= 1.0 - _recovery * 2
		draw_arc(Vector2.ZERO, 165, 0, TAU, 48, pale, 7.0, true)
		for index: int in range(12):
			var axis: Vector2 = Vector2.from_angle(index * TAU / 12)
			draw_line(axis * 35, axis * 130, pale, 3.0)
	elif _effect == &"cleave" and _progress >= 1.0 and _recovery < 0.4:
		pale.a *= 1.0 - _recovery * 2.5
		draw_arc(Vector2.ZERO, 115, 0, TAU, 40, pale, 5.0, true)
	elif _effect == &"hollow_summon" and _recovery < 0.8:
		pale.a *= (0.3 + _progress * 0.7) * (1 - _recovery)
		for index: int in range(3):
			var point: Vector2 = Vector2.from_angle(index * TAU / 3) * 110
			draw_arc(point, 24, 0, TAU, 12, pale, 3.0, true)
	elif _effect == &"phase_change":
		pale.a *= sin(_progress * PI)
		draw_arc(Vector2.ZERO, 55 + _progress * 70, 0, TAU, 32, pale, 4.0, true)
	elif _effect == &"attack" and _progress >= 1.0 and _recovery < 0.4:
		pale.a *= 1.0 - _recovery * 2.5
		var side: float = -1.0 if _direction.x < 0 else 1.0
		draw_line(Vector2(side * 35, -85), Vector2(side * 80, -5), pale, 5.0)

func locomotion(delta: float, moving: bool, direction: Vector2) -> void:
	super.locomotion(delta, moving, direction)
	_effect = &""
