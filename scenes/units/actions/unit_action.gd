class_name UnitAction
extends Node
## Physics-clock action events. A sprite presenter can replace the shape presenter.
signal started(action: StringName)
signal impact(action: StringName)
signal finished(action: StringName)
const ATTACK_TIMES: Dictionary = {
	"knight": Vector2(0.25, 0.24), "militia": Vector2(0.11, 0.18),
	"swordsman": Vector2(0.15, 0.16), "guard": Vector2(0.13, 0.18),
	"archer": Vector2(0.30, 0.18), "healer": Vector2(0.30, 0.20),
	"orc": Vector2(0.30, 0.27), "troll": Vector2(0.48, 0.38),
	"spider": Vector2(0.09, 0.13), "bonecaller": Vector2(0.34, 0.22),
	"minion": Vector2(0.13, 0.14),
}
const DEATH_TIMES: Dictionary = {
	"knight": 0.65, "militia": 0.40, "swordsman": 0.50, "guard": 0.72,
	"archer": 0.55, "healer": 0.68, "orc": 0.62, "troll": 0.95,
	"spider": 0.48, "bonecaller": 0.78, "minion": 0.44,
}
var state: StringName = &"idle"
var phase: StringName = &"idle"
var presenter: UnitActionVisual
var _unit: Unit
var _elapsed: float = 0.0
var _windup: float = 0.0
var _recovery: float = 0.0
var _impacted: bool = false
var _callback: Callable
var _direction: Vector2 = Vector2.LEFT
# Each current unit has at most one periodic support cast (heal or summon).
var _cast_kind: StringName
var _cast_interval: float = 0.0
var _cast_left: float = 0.0
var _cast_windup: float = 0.0
var _cast_decided: bool = false
var _cast_skipped: bool = false
var _cast_callback: Callable
var _cast_eligible: Callable
var _cast_prepare: Callable

func setup(unit: Unit, visual: Node2D, parts: PackedStringArray) -> void:
	_unit = unit
	presenter = UnitActionVisual.new()
	presenter.name = "ActionVisual"
	unit.add_child(presenter)
	presenter.setup(visual, unit.action_style, parts)

func attack_timing() -> Vector2:
	return ATTACK_TIMES.get(_unit.action_style, Vector2(0.15, 0.16))

func is_busy() -> bool:
	return state not in [&"idle", &"move"]

func can_attack() -> bool:
	var timing: Vector2 = attack_timing()
	# Reserve the upcoming cast's anticipation window without resetting attack cooldown.
	return not is_busy() and (_cast_kind == &"" or _cast_left > _cast_windup + timing.x + timing.y + 0.04)

func begin_attack(callback: Callable, direction: Vector2, ranged: bool) -> bool:
	if not can_attack() or _unit.is_dead or _unit.is_emerging:
		return false
	var timing: Vector2 = attack_timing()
	_begin(&"ranged" if ranged else &"attack", timing.x, timing.y, callback, direction)
	return true

func configure_cast(kind: StringName, interval: float, anticipation: float, callback: Callable, eligible: Callable = Callable(), prepare: Callable = Callable()) -> void:
	_cast_kind = kind
	_cast_interval = maxf(0.01, interval)
	_cast_left = _cast_interval
	_cast_windup = minf(anticipation, _cast_interval)
	_cast_callback = callback
	_cast_eligible = eligible
	_cast_prepare = prepare

func begin_emergence(duration: float, callback: Callable) -> void:
	_begin(&"emerge", duration, 0.0, callback, _unit.facing_direction)

func die() -> void:
	# Drop every pending gameplay callback before starting the cosmetic death action.
	_callback = Callable()
	_cast_kind = &""
	_cast_callback = Callable()
	_cast_eligible = Callable()
	_cast_prepare = Callable()
	_begin(&"death", DEATH_TIMES.get(_unit.action_style, 0.5), 0.0, _unit.queue_free, _unit.facing_direction)

func _begin(kind: StringName, windup: float, recovery: float, callback: Callable, direction: Vector2) -> void:
	state = kind
	phase = &"windup"
	_elapsed = 0.0
	_windup = windup
	_recovery = recovery
	_impacted = false
	_callback = callback
	_direction = direction
	presenter.pose(kind, 0.0, 0.0, direction)
	started.emit(kind)

func _physics_process(delta: float) -> void:
	if _unit.is_queued_for_deletion():
		return
	if _unit.is_dead and state != &"death":
		die()
	if _cast_kind != &"" and not _unit.is_dead:
		_cast_left -= delta
	if is_busy():
		_advance(delta)
	else:
		state = &"move" if _unit.velocity.length() > 0.5 else &"idle"
		phase = state
		presenter.locomotion(delta, state == &"move", _unit.facing_direction)
	if _cast_kind == &"" or _unit.is_dead:
		return
	if not _cast_decided and _cast_left <= _cast_windup and not is_busy():
		_cast_decided = true
		_cast_skipped = _cast_eligible.is_valid() and not _cast_eligible.call()
		if not _cast_skipped:
			if _cast_prepare.is_valid():
				_cast_prepare.call()
			_begin(_cast_kind, maxf(0.0, _cast_left), 0.22, _cast_callback, _unit.facing_direction)
	if _cast_skipped and _cast_left <= 0.0:
		_next_cast_cycle()

func _next_cast_cycle() -> void:
	_cast_left += _cast_interval
	_cast_decided = false
	_cast_skipped = false

func _advance(delta: float) -> void:
	_elapsed += delta
	var kind: StringName = state
	if not _impacted and _elapsed + 0.000001 >= _windup:
		_impacted = true
		phase = &"impact"
		# Set the impact pose before calling authoritative combat code.
		presenter.pose(kind, 1.0, 0.0, _direction)
		var callback: Callable = _callback
		_callback = Callable()
		if kind == _cast_kind:
			_next_cast_cycle()
		if callback.is_valid():
			callback.call()
		impact.emit(kind)
		# A callback may kill the owner or replace its action.
		if state != kind or _unit.is_queued_for_deletion():
			return
	if _elapsed + 0.000001 >= _windup + _recovery:
		state = &"idle"
		phase = &"idle"
		if kind != &"death":
			presenter.locomotion(0.0, false, _unit.facing_direction)
		finished.emit(kind)
	elif _impacted:
		phase = &"recovery"
		presenter.pose(kind, 1.0, clampf((_elapsed - _windup) / maxf(_recovery, 0.001), 0.0, 1.0), _direction)
	else:
		presenter.pose(kind, _elapsed / maxf(_windup, 0.001), 0.0, _direction)
