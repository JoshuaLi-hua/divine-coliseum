class_name FocusTargetMarker
extends Node2D
## Lightweight world marker that follows the active Focus Target.

var _target: Unit


func bind(target: Unit) -> void:
	_target = target
	set_process(true)
	queue_redraw()


func _process(_delta: float) -> void:
	if not GameManager.is_valid_focus_target(_target):
		hide()
		return
	show()
	global_position = _target.global_position


func _draw() -> void:
	draw_arc(Vector2.ZERO, 54.0, 0.0, TAU, 64, Color.WHITE, 3.0)
	draw_line(Vector2(-70, 0), Vector2(-48, 0), Color.WHITE, 3.0)
	draw_line(Vector2(48, 0), Vector2(70, 0), Color.WHITE, 3.0)
	draw_line(Vector2(0, -70), Vector2(0, -48), Color.WHITE, 3.0)
	draw_line(Vector2(0, 48), Vector2(0, 70), Color.WHITE, 3.0)
