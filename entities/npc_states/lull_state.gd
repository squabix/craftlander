class_name LullState
extends SequenceState

@export var next_state: StringName
@export var retreat_state: StringName

@export_group("Timing")
@export_range(0.0, 1.0) var retreat_chance := 0.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var gap := 1.3
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var target_poll_interval := 0.2

var _retreated := false


func run() -> void:
	if not await wait_for_target():
		return

	if not _retreated:
		on_lull()
		if should_retreat():
			_retreated = true
			go_to(retreat_state)
			return
	_retreated = false

	if await wait(get_gap()):
		go_to(next_state)


func wait_for_target() -> bool:
	while is_alive():
		var interrupt := get_interrupt()
		if interrupt != &"":
			go_to(interrupt)
			return false

		if has_target():
			return true
		if not await wait(target_poll_interval):
			return false

	return false


func should_retreat() -> bool:
	return retreat_state != &"" and randf() < retreat_chance


func get_interrupt() -> StringName:
	return &""


func has_target() -> bool:
	return true


func on_lull() -> void:
	pass


func get_gap() -> float:
	return gap
