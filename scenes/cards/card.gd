class_name SummonCard
extends Panel

signal dragging_changed(active: bool)
signal dropped(card: SummonCard, viewport_position: Vector2)
@export var data: CardData
var upgrade_level: int = 1
var card_id: int = -1
var consumed: bool = false
var interaction_locked: bool = false
var dragging: bool = false
var _home: Vector2
var _grab_offset: Vector2

func _ready() -> void:
	$Name.text = data.display_name
	$Cost.text = "★".repeat(upgrade_level) + "  |  Cost: %d" % data.divine_power_cost

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not consumed and not interaction_locked:
		_home = position
		_grab_offset = event.position
		dragging = true
		dragging_changed.emit(true)
		accept_event()

func _input(event: InputEvent) -> void:
	if not dragging:
		return
	if event is InputEventMouseMotion:
		global_position = event.position - _grab_offset
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false
		dragging_changed.emit(false)
		dropped.emit(self, event.position)
		if not consumed:
			position = _home
		get_viewport().set_input_as_handled()

func consume() -> void:
	consumed = true
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(false)

func set_interaction_locked(locked: bool) -> void:
	interaction_locked = locked
	if locked and dragging:
		dragging = false
		position = _home
		dragging_changed.emit(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE if locked or consumed else Control.MOUSE_FILTER_STOP
