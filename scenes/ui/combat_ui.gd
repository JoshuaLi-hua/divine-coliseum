extends CanvasLayer

@onready var _card: SummonCard = $Screen/Card
@onready var _power_label: Label = $Screen/DivinePower
@onready var _region: Node2D = get_parent().get_node("Arena/SummonRegion")

func _ready() -> void:
	GameManager.divine_power_changed.connect(_update_power)
	GameManager.reset_divine_power()
	_card.dragging_changed.connect(_on_dragging_changed)
	_card.dropped.connect(_on_card_dropped)

func _update_power(value: float) -> void:
	_power_label.text = "Divine Power: %d / 10" % floori(value)

func _on_dragging_changed(active: bool) -> void:
	_region.visible = active

func _on_card_dropped(card: SummonCard, viewport_position: Vector2) -> void:
	if card.consumed:
		return
	if _region.try_summon(card.unit_scene, viewport_position, card.divine_power_cost) != null:
		card.consume()
