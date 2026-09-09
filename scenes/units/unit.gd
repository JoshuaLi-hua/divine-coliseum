extends CharacterBody2D
## Minimal shared foundation. Stats are inert until later gameplay steps.

@export var unit_name: String = "Unit"
@export var max_health: int = 1
@export var move_speed: float = 0.0
@export var attack_damage: int = 0
@export var attack_range: float = 0.0
@export var attack_cooldown: float = 1.0

var current_health: int = 0


func _ready() -> void:
	current_health = max_health
