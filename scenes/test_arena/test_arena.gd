extends Node2D
## Standalone sandbox: intentionally no BattleManager, deck, or progression callbacks.
const CARD_SCENE := preload("res://scenes/cards/card.tscn")
const SCARECROW := preload("res://scenes/test_arena/test_scarecrow.tscn")
const GROUND := preload("res://scenes/test_arena/forest_ground.gd")
const FOCUS_TARGET_MARKER := preload("res://scenes/ui/focus_target_marker.gd")
const DUMMY_POSITION := Vector2(340, 0)
@export var test_card_data: CardData = preload("res://scenes/test_arena/test_unit_placeholder.tres")
var dummy: Unit
var test_card: SummonCard
var dummy_hp: Label
var dummy_bar: ProgressBar
var reset_button: Button
var clear_button: Button
var back_button: Button
var focus_button: Button
var status: Label
var focus_selecting: bool = false
var focus_marker: FocusTargetMarker
var _leaving: bool = false
@onready var unit_layer: Node2D = $UnitLayer

func _ready() -> void:
	GameManager.reset_relics()
	GameManager.reset_focus_command()
	_build_ui()
	focus_marker = FOCUS_TARGET_MARKER.new()
	focus_marker.hide()
	unit_layer.add_child(focus_marker)
	GameManager.focus_command_changed.connect(_update_focus_button)
	reset_dummy()

func _unhandled_input(event: InputEvent) -> void:
	if not focus_selecting:
		return
	if event.is_action_pressed("ui_cancel"):
		_cancel_focus_selection()
		get_viewport().set_input_as_handled()
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var target := _enemy_at_viewport_position(mouse_event.position)
	if target != null and GameManager.start_focus_target(target):
		focus_selecting = false
		focus_marker.bind(target)
		status.text = "Focus Target active."
	else:
		focus_selecting = false
		status.text = "Focus Target canceled."
	_update_focus_button()
	get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	var hp: int = dummy.current_health if is_instance_valid(dummy) else 0
	dummy_hp.text = "HP %d / 9999" % hp
	dummy_bar.value = hp

func _build_ui() -> void:
	var screen := Control.new()
	screen.name = "Screen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(screen)
	_label(screen, "TEST ARENA", Rect2(24, 20, 800, 42), 32)
	_label(screen, "Try Units • Test Damage • Practice Animations", Rect2(24, 65, 900, 32), 21)
	var instructions := _panel(screen, Rect2(20, 240, 245, 330))
	_label(instructions, "HOW TO TEST", Rect2(16, 12, 213, 35), 22)
	var steps := _label(instructions, "1. Drag a card into the summon zone.\n\n2. Summon at 0 Power.\n\n3. Attack the dummy.\n\n4. Reset or clear.", Rect2(16, 57, 213, 255), 19)
	steps.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var target_panel := _panel(screen, Rect2(1655, 240, 245, 280))
	_label(target_panel, "TEST SCARECROW", Rect2(14, 12, 220, 32), 21)
	dummy_hp = _label(target_panel, "HP 9999 / 9999", Rect2(14, 58, 220, 32), 22)
	dummy_bar = ProgressBar.new()
	dummy_bar.position = Vector2(14, 102)
	dummy_bar.size = Vector2(216, 20)
	dummy_bar.max_value = 9999
	dummy_bar.show_percentage = false
	dummy_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.82, 0.82, 0.75)
	dummy_bar.add_theme_stylebox_override("fill", fill)
	target_panel.add_child(dummy_bar)
	var note := _label(target_panel, "Stationary damage target\nReset after destruction.", Rect2(14, 143, 216, 120), 18)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(screen, "DIVINE POWER\n10 / 10", Rect2(30, 910, 260, 90), 26)
	status = _label(screen, "Reusable card • 0 Power", Rect2(500, 730, 920, 32), 20)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	test_card = CARD_SCENE.instantiate()
	test_card.name = "TestCard"
	test_card.data = test_card_data
	test_card.position = Vector2(800, 766)
	screen.add_child(test_card)
	test_card.dragging_changed.connect(func(active: bool): $ForestGround.highlight_summon = active)
	test_card.dropped.connect(_on_card_dropped)
	reset_button = _button(screen, "RESET DUMMY", Rect2(1620, 875, 280, 62), reset_dummy)
	clear_button = _button(screen, "CLEAR UNITS", Rect2(1620, 955, 280, 62), clear_units)
	focus_button = _button(screen, "FOCUS TARGET", Rect2(1620, 795, 280, 62), _begin_focus_selection)
	back_button = _button(screen, "BACK TO MAIN GAME", Rect2(1560, 22, 340, 62), back_to_main)
	_build_relic_test_ui(screen)

func _begin_focus_selection() -> void:
	if focus_selecting:
		_cancel_focus_selection()
		return
	if not GameManager.is_focus_ready():
		return
	focus_selecting = true
	status.text = "Click the enemy scarecrow."
	_update_focus_button()

func _cancel_focus_selection() -> void:
	focus_selecting = false
	status.text = "Focus Target canceled."
	_update_focus_button()

func _enemy_at_viewport_position(viewport_position: Vector2) -> Unit:
	var world_position: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * viewport_position
	if GameManager.is_valid_focus_target(dummy) and dummy.global_position.distance_to(world_position) <= 80.0:
		return dummy
	return null

func _update_focus_button() -> void:
	if not is_instance_valid(focus_button):
		return
	if focus_selecting:
		focus_button.text = "SELECT ENEMY..."
	elif GameManager.focus_cooldown_remaining > 0.0:
		focus_button.text = "FOCUS TARGET (%.1f)" % GameManager.focus_cooldown_remaining
	else:
		focus_button.text = "FOCUS TARGET"
	focus_button.disabled = _leaving or GameManager.focus_cooldown_remaining > 0.0
	if is_instance_valid(focus_marker) and GameManager.get_focus_target() == null:
		focus_marker.hide()

func _build_relic_test_ui(screen: Control) -> void:
	var panel := _panel(screen, Rect2(20, 590, 360, 300))
	_label(panel, "TEST RELICS", Rect2(14, 10, 330, 30), 21)
	var relics := RelicCatalog.all_relics()
	for index: int in range(relics.size()):
		var relic: RelicData = relics[index]
		var button := _button(panel, relic.display_name, Rect2(14, 48 + index * 39, 332, 33), Callable())
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_grant_test_relic.bind(relic.id, button))
		_update_relic_button(button, relic)

func _grant_test_relic(id: StringName, button: Button) -> void:
	var relic := RelicCatalog.get_relic(id)
	var acquired := GameManager.add_relic(id)
	_update_relic_button(button, relic)
	status.text = "%s %s" % [relic.display_name, "acquired" if acquired else "already active"]

func _update_relic_button(button: Button, relic: RelicData) -> void:
	button.text = ("✓ " if GameManager.has_relic(relic.id) else "") + relic.display_name

func _label(parent: Node, text: String, rect: Rect2, font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.88, 0.88, 0.82))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _panel(parent: Node, rect: Rect2) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.075, 0.07, 0.96)
	style.set_border_width_all(2)
	style.border_color = Color(0.38, 0.39, 0.35)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _button(parent: Node, caption: String, rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 22)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.18, 0.19, 0.17) if state == "hover" else Color(0.075, 0.08, 0.07)
		style.set_border_width_all(2)
		style.border_color = Color(0.65, 0.66, 0.6)
		button.add_theme_stylebox_override(state, style)
	if callback.is_valid():
		button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _on_card_dropped(_card: SummonCard, viewport_position: Vector2) -> void:
	var world_position := get_canvas_transform().affine_inverse() * viewport_position
	summon_test_unit(world_position)
	# Do not consume or replace the card: SummonCard returns it to its home position.

func summon_test_unit(world_position: Vector2) -> Unit:
	if _leaving or not GROUND.SUMMON_RECT.has_point(to_local(world_position)):
		status.text = "Drop inside the outlined player zone."
		return null
	if test_card_data.unit_scene == null:
		status.text = "Assign a unit scene to the test Resource."
		return null
	for child: Node in unit_layer.get_children():
		if child is Unit and not child.is_dead and child.global_position.distance_to(world_position) < 48:
			status.text = "Choose a clear spot in the summon zone."
			return null
	var instance: Node = test_card_data.unit_scene.instantiate()
	if not instance is Unit:
		instance.free()
		status.text = "The test scene must inherit Unit."
		return null
	var unit: Unit = instance as Unit
	unit.team = Unit.Team.PLAYER
	test_card_data.apply_summon_stats(unit, test_card.upgrade_level)
	unit.position = unit_layer.to_local(world_position)
	unit_layer.add_child(unit)
	status.text = "Summoned %s • drag again to repeat" % unit.unit_name
	return unit

func reset_dummy() -> void:
	GameManager.clear_focus_target()
	if is_instance_valid(dummy):
		unit_layer.remove_child(dummy)
		dummy.queue_free()
	dummy = SCARECROW.instantiate()
	dummy.position = DUMMY_POSITION
	unit_layer.add_child(dummy)
	status.text = "Scarecrow reset • 9999 HP"

func clear_units() -> void:
	GameManager.clear_focus_target()
	# Includes sibling minions, corpses, and in-flight projectiles, regardless of team.
	for child: Node in unit_layer.get_children():
		if child == dummy or child == focus_marker:
			continue
		unit_layer.remove_child(child)
		child.queue_free()
	status.text = "Test units cleared • Scarecrow retained"

func back_to_main() -> void:
	if _leaving:
		return
	_leaving = true
	GameManager.reset_relics()
	GameManager.reset_focus_command()
	test_card.set_interaction_locked(true)
	back_button.disabled = true
	_return_to_main.call_deferred()

func _return_to_main() -> void:
	var result := get_tree().change_scene_to_file("res://scenes/main/main.tscn")
	if result != OK:
		_leaving = false
		back_button.disabled = false
		test_card.set_interaction_locked(false)
		status.text = "Could not open main game: " + error_string(result)
