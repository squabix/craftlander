extends Node
class_name Stamina

signal started_fill
signal became_depleted
signal recovered_from_depletion

@export var bar: InterpolatedBar
@export var idle_timer: Timer

@export_group("Rates")
@export var fill_base_rate := 0.05
@export var fill_acceleration := 0.03
@export var fill_multiplier := 1.0
@export var recovery_threshold := 1.0

var value := 1.0:
	set(to):
		value = clampf(to, 0.0, 1.0)
		if value <= 0.0 and not is_depleted:
			is_depleted = true
		elif value >= recovery_threshold and is_depleted:
			is_depleted = false

var is_depleted := false:
	set(to):
		if is_depleted != to:
			is_depleted = to
			if is_depleted:
				became_depleted.emit()
			else:
				recovered_from_depletion.emit()

var last_value := 1.0
var queued_spend := 0.0
var is_filling := false
var _current_fill_time := 0.0

func _ready() -> void:
	idle_timer.timeout.connect(start_fill)
	idle_timer.one_shot = true

func start_fill() -> void:
	is_filling = true
	_current_fill_time = 0.0
	started_fill.emit()

func spend(amount_per_second: float) -> void:
	if is_depleted:
		return
	queued_spend += amount_per_second

func is_usable() -> bool:
	return value > 0.0 and not is_depleted

func _process(delta: float) -> void:
	bar.target_value = value
	
	if get_tree().paused:
		return
	
	last_value = value
	
	if queued_spend == 0.0 or is_depleted:
		if is_filling:
			_current_fill_time += delta * GameWorld.TIME_SCALE
			
			# Current rate: (Base + Accel * Time) * Multiplier
			value += (fill_base_rate + fill_acceleration * _current_fill_time) * fill_multiplier * delta * GameWorld.TIME_SCALE
			
			# Stop filling if hit max
			if value >= 1.0:
				is_filling = false
				_current_fill_time = 0.0
				
		elif idle_timer.is_stopped() and value < 1.0:
			idle_timer.start()
		
	else:
		# If spending, reset filling state and acceleration
		is_filling = false
		_current_fill_time = 0.0
		
		if not idle_timer.is_stopped():
			idle_timer.stop()
			
		value -= queued_spend * delta * GameWorld.TIME_SCALE
	
	queued_spend = 0.0
