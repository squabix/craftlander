class_name ChasingState
extends TargetingState

@export var item_holder: ItemHolder3D
@export var interval_staggerer: IntervalStaggerer

@export_group("Advancing", "advance")
@export var advance_enabled := true
@export_custom(PROPERTY_HINT_NONE, "m") var advance_goal_distance := 1.5
@export var advance_in_water := false

@export_group("Retreating", "retreat")
@export var retreat_enabled := false
@export_custom(PROPERTY_HINT_NONE, "m") var retreat_goal_distance := 3.0

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

	var distance_to_target := guide.get_distance_to_target()
	var in_attack_range := distance_to_target <= advance_goal_distance and sight.does_see_target()

	# Use item if in range (independent of movement, so retreating doesn't block attacking)
	if in_attack_range:
		if reach_state != &"":
			print("Transition to attacking")
			transition_to(reach_state)
		elif item_holder:
			item_holder.use_item()

	# Retreat if too close
	if retreat_enabled and distance_to_target <= retreat_goal_distance:
		guide.move_backward()

	# Move forward to get in range
	elif not in_attack_range and advance_enabled and (advance_in_water or not is_in_water()):
		guide.move_forward()


func update_path() -> void:
	#if can_lose_target and not can_see_target():
		#if is_instance_valid(sight):
			#sight.lose_target()
		#transition_to(lose_target_state)
		#return
	guide.set_target(get_target_position())
