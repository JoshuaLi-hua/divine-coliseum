class_name BossPhases
extends RefCounted
## Monotonic health thresholds. Crossing several queues one transition at a time.
var phase: int = 1
var thresholds: Array[float] = [0.65, 0.30]

func advance(health: int, maximum: int) -> bool:
	if health <= 0 or phase > thresholds.size():
		return false
	if float(health) / maxi(1, maximum) > thresholds[phase - 1]:
		return false
	phase += 1
	return true
