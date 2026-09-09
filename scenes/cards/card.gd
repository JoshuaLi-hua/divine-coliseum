class_name SummonCard
extends Panel

signal dragging_changed(active: bool)
signal dropped(card: SummonCard, viewport_position: Vector2)
@export var display_name: String = "Unit"
@export var divine_power_cost: int = 0
@export var unit_scene: PackedScene
var consumed: bool = false
var dragging: bool = false
var _home: Vector2
var _grab_offset: Vector2

func _ready() -> void:
	$Name.text = display_name
	$Cost.text = "Cost: %d" % divine_power_cost

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not consumed:
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
