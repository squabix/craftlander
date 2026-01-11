extends Hurtbox3D
class_name RigidBodyKnockbackBox3D

@export var rigid_body: RigidBody3D
@export var base_force: float = 1.0

func hurt(damage: Damage, direction: Vector3=Vector3.ZERO) -> float:
	rigid_body.apply_central_force(direction * base_force * damage.force)
	return super(damage, direction)
