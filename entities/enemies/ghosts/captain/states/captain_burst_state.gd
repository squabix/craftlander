class_name CaptainBurstState
extends CaptainAttackState

const LINE := &"burst"

const ANIM_WINDUP := &"BurstWindupShot"
const ANIM_BURST := &"BurstShot"

const WINDUP_POSE_ROTATION := 0.5
const WINDUP_POSE_SCALE := 1.15
const BURST_POSE_ROTATION := -0.2
const BURST_POSE_DURATION := 0.1

const SHOCKWAVE_RADIUS_SCALE := 1.6
const MUZZLE_FORWARD_OFFSET := 0.8

@export var projectile_scene: PackedScene

@export_group("Burst")
@export var count := 14
@export var rings := 5
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var warning_radius := 5.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var speed := 12.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var ring_delay := 0.8
@export var damage := 7.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var muzzle_height := 1.4


func run() -> void:
	var wind_up := captain.tell_time(tell)
	var origin := captain.ground(captain.global_position)
	var warning := start_wind_up(origin, wind_up)
	if not await wait(wind_up):
		return

	warning.activate()
	animate_burst()
	if not await fire_rings(origin):
		return

	captain.stop_animation(ANIM_BURST)
	recover()


func start_wind_up(origin: Vector3, duration: float) -> PlanarTelegraph3D:
	var warning := PlanarTelegraphVfx.disc(Spawner3D.root, origin, warning_radius, color, duration)
	begin_tell(LINE, ANIM_WINDUP, WINDUP_POSE_ROTATION, WINDUP_POSE_SCALE, duration)
	return warning


func animate_burst() -> void:
	captain.play_animation(ANIM_BURST)
	captain.pose(BURST_POSE_ROTATION, 1.0, BURST_POSE_DURATION)


func fire_rings(origin: Vector3) -> bool:
	for ring in rings:
		fire_ring(origin, ring)
		if not await wait(ring_delay):
			return false

	return true


func fire_ring(origin: Vector3, ring: int) -> void:
	captain.cannon_fired.emit()
	GhostVFX.shockwave(Spawner3D.root, origin, color, warning_radius * SHOCKWAVE_RADIUS_SCALE)

	var half_gap := TAU / count / 2.0
	for i in count:
		var angle := TAU * i / count + ring * half_gap
		shoot(Vector3(cos(angle), 0.0, sin(angle)))


func shoot(direction: Vector3) -> void:
	if projectile_scene == null:
		Util.node_error("%s has no projectile scene for its ranged attack", captain)
		return

	var projectile := projectile_scene.instantiate() as HitProjectile3D
	Spawner3D.root.add_child(projectile)

	var muzzle := captain.global_position + Vector3.UP * muzzle_height + direction * MUZZLE_FORWARD_OFFSET
	projectile.global_position = muzzle
	projectile.look_at(muzzle + direction, Vector3.UP)
	projectile.damage = Damage.from_base(damage, captain)
	projectile.speed = speed
	projectile.gravity_scale = 0.0
	projectile.launch()
