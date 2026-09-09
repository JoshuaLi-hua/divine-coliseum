extends Node
## Minimal run-level summon resource.
signal divine_power_changed(value: float)

const MAX_DIVINE_POWER: float = 10.0
const STARTING_DIVINE_POWER: float = 5.0
const REGENERATION: float = 1.0
var divine_power: float = STARTING_DIVINE_POWER

func reset_divine_power() -> void:
	divine_power = STARTING_DIVINE_POWER
	divine_power_changed.emit(divine_power)

func _process(delta: float) -> void:
	var next: float = minf(MAX_DIVINE_POWER, divine_power + REGENERATION * delta)
	if next != divine_power:
		divine_power = next
		divine_power_changed.emit(divine_power)

func try_spend(cost: float) -> bool:
	if cost < 0.0 or divine_power < cost:
		return false
	divine_power -= cost
	divine_power_changed.emit(divine_power)
	return true
