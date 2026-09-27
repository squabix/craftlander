class_name CaptainOpenState
extends OpenState

const ANIM_RECOVER := &"RecoverShot"

const CANNON_LOWER_TIME := 0.25
const POSE_TIME := 0.25
const OPEN_POSE_ROTATION := -0.3
const OPEN_POSE_SCALE := 0.92
const LIGHT_ENERGY_SCALE := 2.0

var captain: GhostCaptain:
	get:
		return root as GhostCaptain


func begin_open() -> void:
	super()
	captain.set_light(color, captain.read_aura_energy * LIGHT_ENERGY_SCALE)
	captain.cannon_aim.lower(CANNON_LOWER_TIME)
	captain.pose(OPEN_POSE_ROTATION, OPEN_POSE_SCALE, POSE_TIME)
	captain.play_animation(ANIM_RECOVER)


func end_open() -> void:
	captain.stop_animation(ANIM_RECOVER)
	super()


func settle() -> void:
	captain.pose(0.0, 1.0, POSE_TIME)
	captain.set_light(GhostCaptain.PHASE_COLORS[captain.phase], captain.read_aura_energy)
