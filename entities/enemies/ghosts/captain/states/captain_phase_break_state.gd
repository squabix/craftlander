class_name CaptainPhaseBreakState
extends CaptainState

const LINE := &"roar"

const ANIM_ROAR := &"RoarShot"

const ROAR_POSE_ROTATION := 0.6
const ROAR_POSE_SCALE := 1.05
const SETTLE_POSE_TIME := 0.3

const IMPACT_HEIGHT := 1.2
const SHOCKWAVE_RADIUS := 9.0

@export var next_state := &"Lull"
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var roar_time := 1.8


func run() -> void:
	var phase_color := GhostCaptain.PHASE_COLORS[captain.get_due_phase()]
	begin_phase(phase_color)
	roar()
	if not await wait(roar_time):
		return

	settle(phase_color)
	go_to(next_state)


func begin_phase(phase_color: Color) -> void:
	captain.health.invulnerable = true
	captain.set_phase(captain.get_due_phase())
	captain.voice.say(LINE)
	captain.apply_phase_look()
	captain.set_light(phase_color, captain.read_tell_energy)
	GhostVFX.impact(Spawner3D.root, captain.global_position + Vector3.UP * IMPACT_HEIGHT, phase_color)
	GhostVFX.shockwave(Spawner3D.root, captain.ground(captain.global_position), phase_color, SHOCKWAVE_RADIUS)


func roar() -> void:
	captain.pose(ROAR_POSE_ROTATION, ROAR_POSE_SCALE, roar_time / 2.0)
	captain.play_animation(ANIM_ROAR)


func settle(phase_color: Color) -> void:
	captain.stop_animation(ANIM_ROAR)
	captain.health.invulnerable = false
	captain.pose(0.0, 1.0, SETTLE_POSE_TIME)
	captain.set_light(phase_color, captain.read_aura_energy)
