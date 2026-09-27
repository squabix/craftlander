class_name BurstAttackState
extends SpecialAttackState

const SHOCKWAVE_RADIUS_SCALE := 1.6
const MUZZLE_FORWARD_OFFSET := 0.8

@export var projectile_scene: PackedScene

@export_group("Burst")
@export var count := 14
@export var rings := 5
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var warning_radius := 5.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var speed := 12.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var ring_delay := 0.8
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var muzzle_height := 1.4

@export_group("Pose", "pose")
@export var pose_tell_animation := &""
@export var pose_strike_animation := &""
@export_custom(PROPERTY_HINT_NONE, "suffix:rad") var pose_windup_rotation := 0.5
@export var pose_windup_scale := 1.15
@export_custom(PROPERTY_HINT_NONE, "suffix:rad") var pose_burst_rotation := -0.2
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var pose_burst_duration := 0.1


func run() -> void:
	var wind_up := enemy.tell_time(tell)
	var origin := enemy.ground(enemy.global_position)
	var warning := track(PlanarTelegraphVfx.disc(Spawner3D.root, origin, warning_radius, color, wind_up))
	begin_tell(pose_tell_animation, pose_windup_rotation, pose_windup_scale, wind_up)
	if not await wait(wind_up):
		return

	warning.activate()
	enemy.play_animation(pose_strike_animation)
	pose(pose_burst_rotation, 1.0, pose_burst_duration)
	if not await fire_rings(origin):
		return

	enemy.stop_animation(pose_strike_animation)
	pose(0.0, 1.0, STRIKE_ANIMATION_TIME)
	recover()


func fire_rings(origin: Vector3) -> bool:
	for ring in rings:
		fire_ring(origin, ring)
		if not await wait(ring_delay):
			return false

	return true


func fire_ring(origin: Vector3, ring: int) -> void:
	enemy.fired.emit()
	EnemyVfx.shockwave(Spawner3D.root, origin, color, warning_radius * SHOCKWAVE_RADIUS_SCALE)

	var half_gap := TAU / count / 2.0
	for i in count:
		var angle := TAU * i / count + ring * half_gap
		shoot(Vector3(cos(angle), 0.0, sin(angle)))


func shoot(direction: Vector3) -> void:
	if projectile_scene == null:
		Util.node_error("%s has no projectile scene for its burst", enemy)
		return

	var projectile := projectile_scene.instantiate() as HitProjectile3D
	Spawner3D.root.add_child(projectile)

	var muzzle := enemy.global_position + Vector3.UP * muzzle_height + direction * MUZZLE_FORWARD_OFFSET
	projectile.global_position = muzzle
	projectile.look_at(muzzle + direction, Vector3.UP)
	projectile.damage = Damage.from_base(damage, enemy)
	projectile.speed = speed
	projectile.gravity_scale = 0.0
	projectile.launch()
