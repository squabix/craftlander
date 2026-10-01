class_name DayNightCycle
extends Node

signal day_started
signal night_started

const HALF_CYCLE_DEGREES := 180.0
const DAY_START_PHASE_DEGREES := 90.0

static var current_time := 0.0
static var current_day_number := 0

@export var palette: SkyPalette

@export var sun: DirectionalLight3D
@export var moon: DirectionalLight3D
@export var world_environment: WorldEnvironment

@export_group("Cycle", "cycle")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var cycle_day_length := 450.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var cycle_night_length := 300.0
@export var cycle_speed_multiplier := 1.0

@export_group("State")
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var phase_degrees := 0.0
@export var day_number := 0

var _was_night := false


func _ready() -> void:
	_was_night = is_currently_night()


func apply_palette() -> void:
	if palette == null:
		return
	if is_instance_valid(sun):
		palette.update_sun(sun, get_normalized_time())
	if is_instance_valid(moon):
		palette.update_moon(moon, get_normalized_time())
	if is_instance_valid(world_environment):
		palette.update_environment(world_environment, get_normalized_time())


func _process(delta: float) -> void:
	var cycle_length := cycle_night_length if is_currently_night() else cycle_day_length
	phase_degrees = fmod(phase_degrees + (HALF_CYCLE_DEGREES / cycle_length) * delta * cycle_speed_multiplier, 360.0)

	if is_instance_valid(sun):
		_update_sun_direction()
	apply_palette()
	_sync()

	var night_now := is_currently_night()
	if night_now == _was_night:
		return
	_was_night = night_now
	if night_now:
		night_started.emit()
	else:
		day_number += 1
		day_started.emit()


func _update_sun_direction() -> void:
	var phase_rad := deg_to_rad(phase_degrees)
	var direction_to_sun := Vector3(cos(phase_rad), sin(phase_rad), 0.0)
	sun.global_transform.basis = Basis.looking_at(-direction_to_sun, Vector3(0.0, 1.0, 0.0001))


func reset_to_day_start() -> void:
	phase_degrees = DAY_START_PHASE_DEGREES
	day_number += 1
	_was_night = false
	_sync()


func jump_to_phase(degrees: float) -> void:
	phase_degrees = degrees
	_was_night = is_currently_night()
	if is_instance_valid(sun):
		_update_sun_direction()
	apply_palette()
	_sync()


func is_currently_night() -> bool:
	return phase_degrees >= HALF_CYCLE_DEGREES


func get_normalized_time() -> float:
	return phase_degrees / 360.0


static func is_night() -> bool:
	return current_time >= 0.5


func _sync() -> void:
	current_time = get_normalized_time()
	current_day_number = day_number
