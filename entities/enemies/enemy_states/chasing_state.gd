extends State

@export var guide: EntityGuide3D
@export var default_target: Node3D
@export var sight: RadialSight3D
@export var min_approach_distance := 1.5

@export var can_lose_target := true
@export var lose_target_state := ""

@onready var item_holder: ItemHolder3D = %ItemHolder3D

func update(_delta: float) -> void:
	if can_lose_target and (sight != null and not sight.does_see_target()):
		transition_to(lose_target_state)
		return
	
	if not is_instance_valid(guide):
		printerr("Chasing state of ", root, " has no guide")
		return
	
	guide.set_target(get_target_position())
	guide.face_target()
	
	if guide.get_distance_to_target() > min_approach_distance:
		guide.move_forward()
	else:
		if item_holder:
			item_holder.use_item()

func get_target_position() -> Vector3:
	if sight != null:
		return sight.target_position
	if is_instance_valid(default_target):
		return default_target.global_position
	if is_instance_valid(root):
		return root.global_position
	return Vector3.ZERO
