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
@export var reach_anim_tree: AnimationTree
@export var reach_one_shot_node := &"AttackOneShot"

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
	var in_goal_range := distance_to_target <= advance_goal_distance and sight.does_see_target()

	# Use item if in range (independent of movement, so retreating doesn't block attacking)
	if in_goal_range:
		reach_goal()

	# Retreat if too close
	if retreat_enabled and distance_to_target <= retreat_goal_distance:
		guide.move_backward()

	# Move forward to get in range
	elif not in_goal_range and advance_enabled and (advance_in_water or not is_in_water()):
		guide.move_forward()


func play_reach_item_anim() -> void:
	if not is_instance_valid(reach_anim_tree):
		return
	if not reach_anim_tree is ItemAnimationTree:
		return
	if reach_anim_tree.is_blending:
		return
	reach_anim_tree.play_start()


func reach_goal() -> void:
	if not reach_state.is_empty():
		transition_to(reach_state)
		play_reach_item_anim()
		return
	
	if is_instance_valid(reach_anim_tree):
		if reach_anim_tree is ItemAnimationTree:
			play_reach_item_anim()
			return
		
		var active_path := "parameters/%s/active" % reach_one_shot_node
		if not reach_anim_tree.get(active_path):
			reach_anim_tree.set("parameters/%s/request" % reach_one_shot_node, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		return
	
	elif item_holder:
		item_holder.use_item()


func update_path() -> void:
	guide.set_target(get_target_position())
