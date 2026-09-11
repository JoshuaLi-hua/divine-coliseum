class_name HollowKing
extends Unit
signal health_changed(current: int, maximum: int)
signal phase_changed(phase: int)
const PRESENTER = preload("res://scenes/bosses/hollow_king_visual.gd")
const CLEAVE_RADIUS: float = 115.0
const SLAM_RADIUS: float = 165.0
const CLEAVE_DAMAGE: int = 26
const SLAM_DAMAGE: int = 42
const SLAM_COOLDOWN: float = 9.0
const SLAM_WARNING: float = 0.9
var phases: BossPhases = BossPhases.new()
var cleave_cooldown: float = 7.0
var summon_cooldown: float = 10.0
var cleave_left: float = 7.0
var summon_left: float = 10.0
var slam_left: float = SLAM_COOLDOWN
@onready var reinforcements: BossReinforcements = $Reinforcements

func create_action_presenter() -> UnitActionVisual:
	return PRESENTER.new()

func _ready() -> void:
	super._ready()
	actions.finished.connect(_on_action_finished)

func take_damage(amount: int, direction_to_source: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	super.take_damage(amount, direction_to_source)
	health_changed.emit(current_health, max_health)
	if not is_dead and actions.state != &"phase_change":
		_advance_phase()

func _advance_phase() -> void:
	if is_dead or not phases.advance(current_health, max_health):
		return
	_attack_target = null
	velocity = Vector2.ZERO
	actions.cancel_current()
	if phases.phase == 3:
		move_speed = 68.0
		attack_cooldown = 1.6
		cleave_cooldown = 5.0
		summon_cooldown = 8.0
	cleave_left = cleave_cooldown
	summon_left = summon_cooldown
	slam_left = SLAM_COOLDOWN
	_attack_time_left = attack_cooldown
	(actions.presenter as HollowKingVisual).boss_phase = phases.phase
	actions.begin_special(&"phase_change", 1.0, 0.0, Callable(), facing_direction)
	phase_changed.emit(phases.phase)

func _on_action_finished(kind: StringName) -> void:
	if kind == &"phase_change":
		# A single large hit may cross both thresholds; each cue still occurs once.
		_advance_phase()

func _physics_process(delta: float) -> void:
	if is_dead or is_queued_for_deletion():
		return
	if actions.state != &"phase_change":
		cleave_left = maxf(0.0, cleave_left - delta)
		if phases.phase >= 2:
			summon_left = maxf(0.0, summon_left - delta)
		if phases.phase == 3:
			slam_left = maxf(0.0, slam_left - delta)
	if not actions.is_busy():
		_choose_special()
	super._physics_process(delta)

func _choose_special() -> void:
	if phases.phase == 3 and slam_left <= 0.0 and _has_players_in_radius(SLAM_RADIUS):
		if actions.begin_special(&"royal_slam", SLAM_WARNING, 0.65, _slam, facing_direction):
			slam_left = SLAM_COOLDOWN
	elif phases.phase >= 2 and summon_left <= 0.0 and reinforcements.can_summon():
		if actions.begin_special(&"hollow_summon", 0.8, 0.4, reinforcements.summon, facing_direction):
			summon_left = summon_cooldown
	elif cleave_left <= 0.0 and _has_players_in_radius(CLEAVE_RADIUS):
		if actions.begin_special(&"cleave", 0.65, 0.5, _cleave, facing_direction):
			cleave_left = cleave_cooldown

func _has_players_in_radius(radius: float) -> bool:
	for node: Node in get_tree().get_nodes_in_group("units"):
		var unit: Unit = node as Unit
		if unit != null and unit.team == Team.PLAYER and unit.is_targetable() and global_position.distance_to(unit.global_position) <= radius:
			return true
	return false

func _damage_area(radius: float, amount: int) -> void:
	if is_dead:
		return
	for node: Node in get_tree().get_nodes_in_group("units"):
		var unit: Unit = node as Unit
		if unit != null and unit.team == Team.PLAYER and unit.is_targetable() and global_position.distance_to(unit.global_position) <= radius:
			unit.take_damage(amount, unit.global_position.direction_to(global_position))

func _cleave() -> void:
	_damage_area(CLEAVE_RADIUS, CLEAVE_DAMAGE)

func _slam() -> void:
	_damage_area(SLAM_RADIUS, SLAM_DAMAGE)
