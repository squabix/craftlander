extends Node
class_name Hunger

@export var bar: InterpolatedBar
@export_range(0.0, 1.0) var value := 0.75:
	set(to):
		value = clampf(to, 0.0, 1.0)
@export var loss_per_minute := 0.2
@export var loss_multiplier := 1.0

@export_group("Health")
@export var health: Health
@export var hurt_curve: Curve
@export var regeneration_curve: Curve
@export var hurt_frequency := 1.0

@export_group("Stamina")
@export var stamina: Stamina
@export var stamina_hunger_loss := 0.1

var hurt_timer: Timer
var queued_loss := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hurt_timer = Timer.new()
	add_child(hurt_timer)
	hurt_timer.start()
	hurt_timer.timeout.connect(
		func() -> void:
			health.hurt(hurt_curve.sample(value))
	)
	if stamina:
		stamina.spent.connect(
			func(amount: float) -> void:
				lose(amount * stamina_hunger_loss)
		)

func _process(delta: float) -> void:
	bar.target_value = value
	if get_tree().paused:
		return
	
	lose(loss_per_minute * loss_multiplier / 60.0)
	value -= queued_loss * delta * GameWorld.TIME_SCALE
	queued_loss = 0.0
	
	health.heal(regeneration_curve.sample(value) * delta * GameWorld.TIME_SCALE)

func lose(amount: float) -> void:
	queued_loss += amount
