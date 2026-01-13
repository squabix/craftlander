extends Node
class_name Hunger

@export var bar: InterpolatedBar
@export_range(0.0, 1.0) var value := 0.75:
	set(to):
		value = clampf(to, 0.0, 1.0)
@export var loss_per_minute := 0.2
@export var loss_multiplier := 1.0
@export var health: Health
@export var hurt_curve: Curve
@export var regeneration_curve: Curve
@export var hurt_frequency := 1.0

var hurt_timer: Timer

func _ready() -> void:
	hurt_timer = Timer.new()
	add_child(hurt_timer)
	hurt_timer.start()
	hurt_timer.timeout.connect(
		func() -> void:
			health.hurt(hurt_curve.sample(value))
	)

func _process(delta: float) -> void:
	value -= (loss_per_minute * loss_multiplier / 60.0) * delta * GameWorld.TIME_SCALE
	bar.value = value
	health.heal(regeneration_curve.sample(value) * delta * GameWorld.TIME_SCALE)
