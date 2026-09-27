class_name CaptainRetreatState
extends HopBackState

var captain: GhostCaptain:
	get:
		return root as GhostCaptain


func puff() -> void:
	EnemyVfx.impact(Spawner3D.root, captain.global_position + Vector3.UP * IMPACT_HEIGHT, GhostCaptain.PHASE_COLORS[captain.phase])
