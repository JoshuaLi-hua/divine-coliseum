class_name Unit
extends CharacterBody2D
## Shared targeting, melee movement, and cooldown-based combat.

signal died(unit: Unit)

enum Team { PLAYER, ENEMY }
enum AttackMode { MELEE, PROJECTILE }

@export var attack_mode: AttackMode = AttackMode.MELEE
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 650.0

@export var block_enabled: bool = false
@export_range(0.0, 1.0) var frontal_damage_reduction: float = 0.5
@export_range(0.0, 360.0) var frontal_block_arc: float = 120.0
var facing_direction: Vector2 = Vector2.LEFT
var _block_tween: Tween
var _visual_rest_scale: Vector2

@export var team: Team = Team.PLAYER
@export var unit_name: String = "Unit"
@export var max_health: int = 1
@export var move_speed: float = 0.0
@export var attack_damage: int = 0
@export var attack_range: float = 0.0
@export var attack_cooldown: float = 1.0

var current_health: int = 0
var current_target: Unit = null
var is_dead: bool = false
var _attack_time_left: float = 0.0
var _hit_tween: Tween
var _visual_rest_modulate: Color
var _attack_tween: Tween
var _visual_rest_position: Vector2

@onready var _health_bar: Node2D = $HealthBar
@onready var _health_fill: ColorRect = $HealthBar/Fill
@onready var _visual: Node2D = $Visual


func _ready() -> void:
	_visual_rest_scale = _visual.scale
	facing_direction = Vector2.RIGHT if team == Team.PLAYER else Vector2.LEFT
	_visual_rest_modulate = _visual.modulate
	_visual_rest_position = _visual.position
	current_health = max_health
	_update_health_bar()
	add_to_group("units")


# Target-owned reservations store instance IDs, never strong references.
const SLOT_COUNT: int = 8
const SLOT_RADIUS: float = 38.0
const ALLY_SPACING: float = 29.0
var engagement_slot: int = -1
var _slot_target: Unit
var _slot_owners: Dictionary[int, int] = {}
var _slot_rotation: float = 0.0

func _release_slot() -> void:
	if is_instance_valid(_slot_target):
		_slot_target._slot_owners.erase(engagement_slot)
	_slot_target = null
	engagement_slot = -1

func _exit_tree() -> void:
	_release_slot()

func _reserve_slot(attacker: Unit) -> int:
	for index: int in _slot_owners.keys():
		var owner: Unit = instance_from_id(_slot_owners[index]) as Unit
		if not is_instance_valid(owner) or owner.is_dead or not owner.is_inside_tree() or owner.current_target != self:
			_slot_owners.erase(index)
	# A mutually targeting pair must agree on opposite offsets. Independent
	# nearest slots can otherwise make the pair chase a translating midpoint.
	if current_target == attacker and engagement_slot >= 0 and engagement_slot < SLOT_COUNT:
		var opposite: int = posmod(roundi((attacker._slot_rotation + engagement_slot * TAU / SLOT_COUNT + PI - _slot_rotation) * SLOT_COUNT / TAU), SLOT_COUNT)
		if not _slot_owners.has(opposite):
			_slot_owners[opposite] = attacker.get_instance_id()
			return opposite
	var ring: int = 0
	while true:
		var best: int = -1
		var best_distance: float = INF
		for index: int in range(ring * SLOT_COUNT, (ring + 1) * SLOT_COUNT):
			if _slot_owners.has(index):
				continue
			var distance: float = attacker.global_position.distance_squared_to(_slot_position(index, attacker.attack_range))
			if distance < best_distance:
				best_distance = distance
				best = index
		if best >= 0:
			_slot_owners[best] = attacker.get_instance_id()
			if current_target == attacker and engagement_slot >= 0:
				# Match the existing pair's direction without reassigning anyone's ID.
				# Rotate this target's entire ring once when the mutual pair forms.
				_slot_rotation = attacker._slot_rotation + (engagement_slot % SLOT_COUNT) * TAU / SLOT_COUNT + PI - (best % SLOT_COUNT) * TAU / SLOT_COUNT
			return best
		ring += 1
	return -1

func _has_inner_vacancy() -> bool:
	for index: int in range(SLOT_COUNT):
		if not _slot_owners.has(index):
			return true
	return false

func _slot_position(index: int, reach: float) -> Vector2:
	var ring: int = index / SLOT_COUNT
	var radius: float = minf(SLOT_RADIUS, maxf(0.0, reach - 4.0)) + ring * ALLY_SPACING
	return global_position + Vector2.from_angle(_slot_rotation + (index % SLOT_COUNT) * TAU / SLOT_COUNT) * radius

func _ally_separation() -> Vector2:
	var push: Vector2 = Vector2.ZERO
	for node: Node in get_tree().get_nodes_in_group("units"):
		var ally: Unit = node as Unit
		if ally == self or ally == null or ally.is_dead or ally.team != team:
			continue
		var offset: Vector2 = global_position - ally.global_position
		var distance: float = offset.length()
		if distance >= ALLY_SPACING:
			continue
		if distance < 0.001:
			# Antisymmetric, deterministic tie break for exact spawn stacking.
			var angle: float = float((mini(get_instance_id(), ally.get_instance_id()) * 97) % 360)
			offset = Vector2.from_angle(deg_to_rad(angle)) * (1.0 if get_instance_id() < ally.get_instance_id() else -1.0)
		else:
			offset /= distance
		push += offset * (ALLY_SPACING - distance) * 4.0
	return push.limit_length(60.0)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_attack_time_left = maxf(0.0, _attack_time_left - delta)
	if not _is_valid_opponent(current_target):
		current_target = _find_nearest_opponent()
	if _slot_target != current_target or attack_mode != AttackMode.MELEE:
		_release_slot()
	_update_facing()
	var desired: Vector2 = Vector2.ZERO
	if _is_valid_opponent(current_target):
		var distance: float = global_position.distance_to(current_target.global_position)
		if attack_mode == AttackMode.MELEE:
			if engagement_slot < 0:
				_slot_target = current_target
				engagement_slot = current_target._reserve_slot(self)
			elif engagement_slot >= SLOT_COUNT and current_target._has_inner_vacancy():
				# Waiting rings advance only after a vacancy, never shuffle occupied slots.
				_release_slot()
				_slot_target = current_target
				engagement_slot = current_target._reserve_slot(self)
			var destination: Vector2 = current_target._slot_position(engagement_slot, attack_range)
			var offset: Vector2 = destination - global_position
			desired = (offset * 6.0).limit_length(move_speed)
			if offset.length() <= 7.0 and distance <= attack_range:
				_try_attack()
		else:
			var remaining: float = distance - (attack_range - 2.0)
			if remaining > 0.0:
				desired = global_position.direction_to(current_target.global_position) * minf(move_speed, remaining * 6.0)
			if distance <= attack_range:
				_try_attack()
	velocity = (desired + _ally_separation()).limit_length(move_speed)
	if velocity.length() < 0.5:
		velocity = Vector2.ZERO
	move_and_slide()


func _find_nearest_opponent() -> Unit:
	var nearest: Unit = null
	var nearest_distance_squared: float = INF
	for node: Node in get_tree().get_nodes_in_group("units"):
		var candidate: Unit = node as Unit
		if not _is_valid_opponent(candidate):
			continue
		var distance_squared: float = global_position.distance_squared_to(candidate.global_position)
		if distance_squared < nearest_distance_squared:
			nearest = candidate
			nearest_distance_squared = distance_squared
	return nearest


func _is_valid_opponent(candidate: Unit) -> bool:
	return is_instance_valid(candidate) and candidate != self and candidate.is_inside_tree() and not candidate.is_queued_for_deletion() and not candidate.is_dead and candidate.team != team


func _try_attack() -> void:
	if is_dead or _attack_time_left > 0.0 or not _is_valid_opponent(current_target):
		return
	if global_position.distance_to(current_target.global_position) > attack_range:
		return
	_attack_time_left = attack_cooldown
	_play_attack_cue(global_position.direction_to(current_target.global_position))
	if attack_mode == AttackMode.PROJECTILE:
		_fire_projectile()
	else:
		current_target.take_damage(attack_damage, current_target.global_position.direction_to(global_position))
	if not _is_valid_opponent(current_target):
		current_target = null


func take_damage(amount: int, direction_to_source: Vector2 = Vector2.ZERO) -> void:
	if is_dead or amount <= 0:
		return
	_update_facing()
	var blocked: bool = block_enabled and not direction_to_source.is_zero_approx() and facing_direction.dot(direction_to_source.normalized()) >= cos(deg_to_rad(frontal_block_arc * 0.5)) - 0.000001
	var final_damage: int = amount
	if blocked:
		final_damage = maxi(1, floori(float(amount) * (1.0 - frontal_damage_reduction)))
		_play_block_cue()
	current_health = maxi(0, current_health - final_damage)
	_update_health_bar()
	if current_health == 0:
		_die()
	else:
		_play_hit_cue()


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	_release_slot()
	for owner_id: int in _slot_owners.values():
		var owner: Unit = instance_from_id(owner_id) as Unit
		if is_instance_valid(owner):
			owner._slot_target = null
			owner.engagement_slot = -1
	_slot_owners.clear()
	velocity = Vector2.ZERO
	current_target = null
	set_physics_process(false)
	remove_from_group("units")
	died.emit(self)
	if _attack_tween != null:
		_attack_tween.kill()
	if _hit_tween != null:
		_hit_tween.kill()
	if _block_tween != null:
		_block_tween.kill()
	_visual.scale = _visual_rest_scale
	_health_bar.hide()
	_visual.position = _visual_rest_position
	_visual.modulate = _visual_rest_modulate
	# The fading corpse must not block other living units.
	$CollisionShape2D.set_deferred("disabled", true)
	var death_tween: Tween = create_tween()
	death_tween.tween_property(_visual, "modulate:a", 0.0, 0.2)
	death_tween.tween_callback(queue_free)


func _play_attack_cue(direction: Vector2) -> void:
	if _attack_tween != null:
		_attack_tween.kill()
	_visual.position = _visual_rest_position + direction * 3.0
	_attack_tween = create_tween()
	_attack_tween.tween_property(_visual, "position", _visual_rest_position, 0.12)


func _update_health_bar() -> void:
	_health_fill.scale.x = clampf(float(current_health) / float(maxi(1, max_health)), 0.0, 1.0)


func _play_hit_cue() -> void:
	if _hit_tween != null:
		_hit_tween.kill()
	_visual.modulate = _visual_rest_modulate * Color(0.55, 0.55, 0.55, 1.0)
	_hit_tween = create_tween()
	_hit_tween.tween_property(_visual, "modulate", _visual_rest_modulate, 0.1)


func _fire_projectile() -> void:
	if projectile_scene == null:
		return
	var projectile: Projectile = projectile_scene.instantiate()
	projectile.damage = attack_damage
	projectile.speed = projectile_speed
	projectile.source_team = team
	projectile.target = current_target
	var direction: Vector2 = global_position.direction_to(current_target.global_position)
	var origin: Vector2 = global_position + Vector2(0, -30) + direction * 18.0
	projectile.position = (get_parent() as Node2D).to_local(origin)
	projectile.rotation = direction.angle()
	get_parent().add_child(projectile)


func _update_facing() -> void:
	if not _is_valid_opponent(current_target):
		return
	var offset: Vector2 = current_target.global_position - global_position
	if offset.is_zero_approx():
		return
	facing_direction = offset.normalized()
	# Shield placeholders face left by default; mirror only the visual, not the body.
	if block_enabled and absf(facing_direction.x) > 0.001:
		var horizontal: float = -absf(_visual_rest_scale.x) if facing_direction.x > 0.0 else absf(_visual_rest_scale.x)
		if horizontal != _visual_rest_scale.x:
			if _block_tween != null:
				_block_tween.kill()
			_visual_rest_scale.x = horizontal
			_visual.scale = _visual_rest_scale


func _play_block_cue() -> void:
	if _block_tween != null:
		_block_tween.kill()
	_visual.scale = _visual_rest_scale * 1.08
	_block_tween = create_tween()
	_block_tween.tween_property(_visual, "scale", _visual_rest_scale, 0.12)
