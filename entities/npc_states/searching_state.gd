class_name SearchingState
extends TargetingState

@export var interval_staggerer: IntervalStaggerer

@export_group("Target Losing")
@export var found_target_state := &""
@export var give_up_state := &""
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var reach_distance := 1.5
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var max_search_time := 5.0

var _give_up_at_msec := 0


func enter() -> void:
	if is_instance_valid(guide):
		guide.set_target(sight.target_position)
	if is_instance_valid(interval_staggerer):
		interval_staggerer.disabled = false
	_give_up_at_msec = Time.get_ticks_msec() + roundi(max_search_time * 1000.0)


func exit() -> void:
	if is_instance_valid(interval_staggerer):
		interval_staggerer.disabled = true


func physics_update(_delta: float) -> void:
	if not is_instance_valid(guide):
		Util.node_error("Searching state of %s has no guide", root)
		return
	guide.face_target()
	guide.move_forward()


func check_status() -> void:
	if not is_active:
		return
	
	if can_see_target():
		print("Found target!")
		transition_to(found_target_state)
		return

	if guide.get_distance_to_target() <= reach_distance or Time.get_ticks_msec() >= _give_up_at_msec:
		print("Giving up")
		transition_to(give_up_state)
