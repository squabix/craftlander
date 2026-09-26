class_name CaptainBlinkState
extends CaptainAttackState

const LINE := &"blink"

const ANIM_BLINK_IN := &"BlinkInShot"

const ARRIVAL_POSE_ROTATION := -0.5
const ARRIVAL_POSE_DURATION := 0.08

const ARRIVAL_HEIGHT := 0.8
const LAND_SPREAD := PI
const SHOCKWAVE_RADIUS_SCALE := 1.6

@export_group("Blink")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var min_distance := 4.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var max_distance := 8.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var radius := 3.2
@export var damage := 16.0
@export var knockback := 20.0


func run() -> void:
	var player := captain.get_player()
	if player == null:
		abort()
		return

	var wind_up := captain.tell_time(tell)
	var destination := captain.pick_land_point(player.global_position, min_distance, max_distance, 0.0, LAND_SPREAD)
	var ring := vanish(destination, wind_up)
	if not await wait(wind_up):
		return

	arrive(destination, ring)
	if not await wait(STRIKE_ANIMATION_TIME):
		return

	recover()


func vanish(destination: Vector3, wind_up: float) -> PlanarTelegraph3D:
	var ring := PlanarTelegraphVfx.disc(Spawner3D.root, destination, radius, color, wind_up)
	begin_tell(LINE, &"", NAN, 1.0, wind_up)
	GhostVFX.teleport(Spawner3D.root, captain.global_position + Vector3.UP, color)
	captain.teleported.emit()
	captain.vanish()
	return ring


func arrive(destination: Vector3, ring: PlanarTelegraph3D) -> void:
	captain.global_position = destination + Vector3.UP * ARRIVAL_HEIGHT
	captain.appear()
	captain.set_light(color, captain.read_tell_energy)
	captain.teleported.emit()
	ring.activate()
	animate_arrival(destination)
	hurt_if_in_radius(destination)


func animate_arrival(destination: Vector3) -> void:
	captain.play_animation(ANIM_BLINK_IN)
	captain.pose(ARRIVAL_POSE_ROTATION, 1.0, ARRIVAL_POSE_DURATION)
	GhostVFX.teleport(Spawner3D.root, destination + Vector3.UP, color)
	GhostVFX.shockwave(Spawner3D.root, destination, color, radius * SHOCKWAVE_RADIUS_SCALE)


func hurt_if_in_radius(destination: Vector3) -> void:
	var target := captain.get_player()
	if target == null:
		return

	var offset := target.global_position - destination
	offset.y = 0.0
	if offset.length() > radius + PLAYER_RADIUS:
		return

	var hit := Damage.from_base(damage, captain)
	hit.knockback_force = knockback
	hurt_player(hit)
