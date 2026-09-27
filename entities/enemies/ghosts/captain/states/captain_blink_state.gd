class_name CaptainBlinkState
extends BlinkAttackState

var captain: GhostCaptain:
	get:
		return root as GhostCaptain


func arrive(destination: Vector3, ring: PlanarTelegraph3D) -> void:
	super(destination, ring)
	captain.set_light(color, captain.read_tell_energy)
