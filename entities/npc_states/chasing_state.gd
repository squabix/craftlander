class_name ChasingState
extends TargetingState

const TARGET_CHEST_HEIGHT := 1.0

@export var item_holder: ItemHolder3D
@export var interval_staggerer: IntervalStaggerer
@export var rhythm: AttackRhythm

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

@export_group("Timed Special", "timed_special")
@export var timed_special_state := &""
@export var timed_special_staggerer: IntervalStaggerer
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var timed_special_min_distance := 0.0

var _special_pending := false


func _ready() -> void:
	interval_staggerer.disabled = not is_active
	if is_instance_valid(timed_special_staggerer):
		timed_special_staggerer.disabled = not is_active
	if is_instance_valid(item_holder):
		item_holder.used_item.connect(_on_item_used)


func enter() -> void:
	interval_staggerer.disabled = false
	_special_pending = false
	if is_instance_valid(timed_special_staggerer):
		timed_special_staggerer.reset()
		timed_special_staggerer.disabled = false


func exit() -> void:
	interval_staggerer.disabled = true
	if is_instance_valid(timed_special_staggerer):
		timed_special_staggerer.disabled = true


func is_in_water() -> bool:
	return is_instance_valid(sight.target) and sight.target.get(&"is_in_water") == true


func physics_update(_delta: float) -> void:
	if not is_instance_valid(guide):
		Util.node_error("Chasing state of %s has no guide", root)
		return
	if try_special():
		return

	var distance_to_target := guide.get_distance_to_target()
	var in_goal_range := distance_to_target <= advance_goal_distance and sight.does_see_target()
	
	# Face target
	if in_goal_range:
		guide.face_true_target()
	else:
		guide.face_target()
	_aim_held_item()

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


func try_special() -> bool:
	if _special_pending or not is_instance_valid(rhythm):
		return false

	var special := rhythm.take_ready_special(get_parent() as StateMachine, sight)
	if special == &"":
		return false

	start_special(special)
	return true


func try_timed_special() -> void:
	if not is_active or _special_pending:
		return

	var special := (get_parent() as StateMachine).get_state(timed_special_state) as SpecialAttackState
	if special == null:
		Util.node_error("%s has no timed special state named %s", root, timed_special_state)
		return
	if can_start_timed_special(special):
		start_special(special.name)


func can_start_timed_special(special: SpecialAttackState) -> bool:
	var distance := special.enemy.distance_to_target()
	return distance >= timed_special_min_distance and special.can_start(distance) and sight.does_see_target()


func start_special(state_name: StringName) -> void:
	_special_pending = true
	transition_to(state_name)


func count_basic_attack() -> void:
	if is_active and is_instance_valid(rhythm):
		rhythm.count_basic_attack()


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
			if not is_instance_valid(item_holder):
				count_basic_attack()
		return
	
	elif item_holder:
		item_holder.use_item()


func _aim_held_item() -> void:
	if is_instance_valid(item_holder) and is_instance_valid(sight.target):
		item_holder.aim_at(sight.target.global_position + Vector3.UP * TARGET_CHEST_HEIGHT)


func update_path() -> void:
	if has_no_target():
		transition_to(lose_target_state)
		return
	guide.set_target(get_target_position())


func has_no_target() -> bool:
	return can_lose_target and not lose_target_state.is_empty() and not is_instance_valid(sight.target)


func _on_item_used(_item: Item) -> void:
	count_basic_attack()
