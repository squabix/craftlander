extends State

const STAGGER_RANDOMNESS := 0.03

@export var item_holder: ItemHolder3D
@export var guide: EntityGuide3D
@export var sight: RadialSight3D
@export var default_target: Node3D
@export_custom(PROPERTY_HINT_NONE, "m") var max_item_use_distance := 1.5
@export_custom(PROPERTY_HINT_NONE, "s") var path_update_interval := 0.25

@export_group("Target Losing")
@export var can_lose_target := true
@export var lose_target_state := ""

var _path_update_time_counter := 0.0


func enter() -> void:
	# Stagger the initial timer so multiple enemies don't tick on the exact same frame
	_path_update_time_counter = randf_range(0.0, path_update_interval)


func reset_path_update_time_counter() -> void:
	_path_update_time_counter = path_update_interval + randf_range(-STAGGER_RANDOMNESS, +STAGGER_RANDOMNESS)


func physics_update(_delta: float) -> void:
	if not is_instance_valid(guide):
		printerr("Chasing state of %s has no guide" % root)
		return

	_path_update_time_counter -= _delta
	if _path_update_time_counter <= 0.0:
		# Reset timer with slight randomization to maintain stagger separation
		reset_path_update_time_counter()

		if can_lose_target and not can_see_target():
			transition_to(lose_target_state)
			return

		guide.set_target(get_target_position())

	guide.face_target()

	# Use item if in range
	if guide.get_distance_to_target() <= max_item_use_distance:
		if item_holder:
			item_holder.use_item()

	# Move forward to get in range
	else:
		guide.move_forward()


func can_see_target() -> bool:
	if sight == null:
		return false
	return sight.does_see_target()


func get_target_position() -> Vector3:
	if sight != null:
		return sight.target_position
	if is_instance_valid(default_target):
		return default_target.global_position
	if is_instance_valid(root):
		return root.global_position
	return Vector3.ZERO
