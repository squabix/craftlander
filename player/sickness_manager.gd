extends Node
class_name SicknessManager

const SICK_CONTROLS_VALUE := 0.85

@export var bar: InterpolatedBar
@export_range(0.0, 1.0) var value := 0.0:
	set(to):
		value = clampf(to, 0.0, 1.0)
@export var entity_controller: Controller3D
@export var health: Health
@export var hunger: Hunger
@export var hurt_multiplier_curve: Curve
@export var hunger_multiplier_curve: Curve
@export var sickness_tint: TextureRect
@export var sickness_tint_curve: Curve

var hurt_timer: Timer

func _process(delta: float) -> void:
	entity_controller.using_sick_controls = value > SICK_CONTROLS_VALUE
	bar.value = value
	hunger.loss_multiplier = hunger_multiplier_curve.sample(value)
	health.hurt_multiplier = hurt_multiplier_curve.sample(value)
	sickness_tint.modulate.a = lerp(
		sickness_tint.modulate.a,
		sickness_tint_curve.sample(value),
		0.1
	)
	if Input.is_action_just_pressed("interact"):
		value += 0.1
