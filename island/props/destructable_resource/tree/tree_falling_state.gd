extends State

@export var hurtbox_collision: CollisionShape3D
@export var continue_fall_area: Area3D
@export var trunk: Node3D
@export var animation_player: VisibilityAnimationPlayer
@export var occluder_instance: OccluderInstance3D
@export var falling_mesh_instances: Array[MeshInstance3D]

const FALL_ACCEL := 0.002

var fall_speed := 0.01
var fall_direction: Vector3

func enter() -> void:
	await get_tree().process_frame
	fall_speed = 0.0
	fall_direction = root.hurtbox.last_hurt_direction
	hurtbox_collision.disabled = true
	
	occluder_instance.queue_free()
	
	for instance in falling_mesh_instances:
		MeshInstanceAggregator3D.disassociate_mesh_instance(instance)
	animation_player.disable_visibility_updates()

func has_landed() -> bool:
	return is_instance_valid(continue_fall_area) and continue_fall_area.get_overlapping_bodies().size() > 1

func physics_update(_delta: float) -> void:
	trunk.show()
	
	# Greater than 1 to discount colliding with own trunk
	if has_landed():
		transition_to("Chopped")
		return
	
	if not is_instance_valid(trunk):
		return
	
	fall_speed += FALL_ACCEL
	trunk.global_basis = Util.roll_basis_toward(
			trunk.global_basis,
			fall_direction,
			Util.VECTOR3Y,
			fall_speed
		)
