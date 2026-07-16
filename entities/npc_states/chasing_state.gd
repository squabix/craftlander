extends State

@export var item_holder: ItemHolder3D
@export var guide: EntityGuide3D
@export var sight: RadialSight3D
@export var interval_staggerer: IntervalStaggerer
@export var default_target: Node3D
@export_custom(PROPERTY_HINT_NONE, "m") var max_item_use_distance := 1.5

@export_group("Target Losing")
@export var can_lose_target := true
@export var lose_target_state := &""


func _ready() -> void:
	interval_staggerer.disabled = not is_active


func enter() -> void:
	interval_staggerer.disabled = false


func exit() -> void:
	interval_staggerer.disabled = true


func physics_update(_delta: float) -> void:
	if not is_instance_valid(guide):
		printerr("Chasing state of %s has no guide" % root)
		return

	guide.face_target()

	# Use item if in range
	if guide.get_distance_to_target() <= max_item_use_distance:
		if item_holder:
			item_holder.use_item()

	# Move forward to get in range
	else:
		guide.move_forward()


func update_path() -> void:
	if can_lose_target and not can_see_target():
		transition_to(lose_target_state)
		return
	guide.set_target(get_target_position())


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
