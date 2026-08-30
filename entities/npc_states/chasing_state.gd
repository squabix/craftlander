class_name ChasingState
extends TargetingState

@export var item_holder: ItemHolder3D
@export var interval_staggerer: IntervalStaggerer

@export_group("Advancing", "advance")
@export var advance_enabled := true
@export_custom(PROPERTY_HINT_NONE, "m") var advance_goal_distance := 1.5
@export var advance_in_water := false

@export_group("Reach", "reach")
@export var reach_state := &""

@export_group("Target Losing")
@export var can_lose_target := true
@export var lose_target_state := &""


func _ready() -> void:
	interval_staggerer.disabled = not is_active


func enter() -> void:
	interval_staggerer.disabled = false


func exit() -> void:
	interval_staggerer.disabled = true


func is_in_water() -> bool:
	return is_instance_valid(sight.target) and sight.target.get(&"is_in_water") == true


func physics_update(_delta: float) -> void:
	if not is_instance_valid(guide):
		Util.node_error("Chasing state of %s has no guide", root)
		return

	guide.face_target()

	# Use item if in range
	if guide.get_distance_to_target() <= advance_goal_distance and sight.does_see_target():
		if reach_state != &"":
			print("Transition to attacking")
			transition_to(reach_state)
		elif item_holder:
			item_holder.use_item()

	# Move forward to get in range
	elif advance_enabled and (advance_in_water or not is_in_water()):
		guide.move_forward()


func update_path() -> void:
	#if can_lose_target and not can_see_target():
		#if is_instance_valid(sight):
			#sight.lose_target()
		#transition_to(lose_target_state)
		#return
	guide.set_target(get_target_position())
