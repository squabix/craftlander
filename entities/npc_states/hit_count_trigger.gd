class_name HitCountTrigger
extends SignalStateTrigger

@export var hits_required := 1
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var window := 0.0

var _hit_times: Array[float] = []


func trigger(..._args: Array) -> void:
	if disabled or not is_allowed_state():
		return

	if not count_hit():
		return

	_hit_times.clear()
	super()


func count_hit() -> bool:
	var now := Util.get_time_seconds()
	_hit_times.append(now)
	if window > 0.0:
		forget_hits_before(now - window)
	return _hit_times.size() >= hits_required


func forget_hits_before(time: float) -> void:
	_hit_times.assign(_hit_times.filter(func(hit_time: float) -> bool: return hit_time >= time))


func is_allowed_state() -> bool:
	return from_state_whitelist.is_empty() or from_state_whitelist.any(state_machine.is_currently)
