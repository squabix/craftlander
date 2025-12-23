extends State

const FALL_ACCEL := 0.002

var fall_speed := 0.01

var fall_direction: Vector3

func enter() -> void:
	await get_tree().process_frame
	fall_speed = 0.0
	fall_direction = root.hurtbox.last_hurt_direction

func physics_update(_delta: float) -> void:
	if %ContinueFallArea.has_overlapping_bodies():
		transition_to("Chopped")
	else:
		fall_speed += FALL_ACCEL
		root.trunk.global_basis = Util.roll_basis_toward(
				root.trunk.global_basis,
				fall_direction,
				Util.VECTOR3Y,
				fall_speed
			)
