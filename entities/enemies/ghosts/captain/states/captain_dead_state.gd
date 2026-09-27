class_name CaptainDeadState
extends CaptainState

const ANIM_DEATH := &"DeathShot"

const CANNON_LOWER_TIME := 0.25
const AURA_FADE_TIME := 0.4
const IMPACT_HEIGHT := 1.4

const HITSTOP_TIME_SCALE := 0.05
const HITSTOP_DURATION := 0.15
const SLOWMO_TIME_SCALE := 0.4
const SLOWMO_DURATION := 0.6
const SQUASH_SCALE := 0.55
const PUFF_SHOCKWAVE_RADIUS := 12.0

const KEY_GLOW_COLOR := Color(1.0, 0.85, 0.3)
const KEY_GLOW_RADIUS := 0.5
const KEY_DROP_HEIGHT := 1.0
const KEY_LAND_SEARCH_RADIUS := 25.0

@export var dropper: InventoryDropper3D
@export var key_item: Item
@export var held_key: Node3D
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var linger := 0.75


func run() -> void:
	var phase_color := GhostCaptain.PHASE_COLORS[captain.phase]
	begin_death(phase_color)
	drop_key()

	await slow_motion()
	await squash_and_linger()
	puff_away(phase_color)


func begin_death(phase_color: Color) -> void:
	captain.play_animation(ANIM_DEATH)
	captain.cannon_aim.lower(CANNON_LOWER_TIME)
	if is_instance_valid(held_key):
		held_key.hide()

	captain.appear()
	clear_hazards()
	if is_instance_valid(captain.beacon):
		captain.beacon.visible = false

	captain.set_light(phase_color, 0.0)
	captain.fade_aura(AURA_FADE_TIME)
	EnemyVfx.impact(Spawner3D.root, captain.global_position + Vector3.UP * IMPACT_HEIGHT, phase_color)


func clear_hazards() -> void:
	PlanarTelegraph3D.clear_all()
	Cannonball.clear_all()


func slow_motion() -> void:
	Engine.time_scale = HITSTOP_TIME_SCALE
	await get_tree().create_timer(HITSTOP_DURATION, true, false, true).timeout

	Engine.time_scale = SLOWMO_TIME_SCALE
	await get_tree().create_timer(SLOWMO_DURATION, true, false, true).timeout

	Engine.time_scale = 1.0


func squash_and_linger() -> void:
	create_tween().tween_property(captain.visuals, ^"scale:y", captain.base_scale.y * SQUASH_SCALE, linger / 2.0)
	await get_tree().create_timer(linger, false).timeout


func drop_key() -> void:
	if not is_instance_valid(dropper) or key_item == null:
		Util.node_error("%s cannot drop the captain's key without a dropper and key item", captain)
		return

	var pickup := dropper.add_pickup(key_item)
	if is_instance_valid(pickup):
		pickup.global_position = get_key_drop_point()
		glow_key(pickup)


func get_key_drop_point() -> Vector3:
	var below := captain.ground(dropper.global_position)
	if not captain.is_dry(below):
		below = captain.pick_land_point(dropper.global_position, 0.0, KEY_LAND_SEARCH_RADIUS, 0.0, PI)
	return below + Vector3.UP * KEY_DROP_HEIGHT


func glow_key(pickup: Node3D) -> void:
	var aura := EnemyVfx.aura(pickup, pickup.global_position, KEY_GLOW_COLOR, KEY_GLOW_RADIUS)
	aura.process_mode = Node.PROCESS_MODE_PAUSABLE
	aura.visibility_range_end = 0.0


func puff_away(phase_color: Color) -> void:
	EnemyVfx.teleport(Spawner3D.root, captain.global_position + Vector3.UP * IMPACT_HEIGHT, phase_color)
	EnemyVfx.shockwave(Spawner3D.root, captain.ground(captain.global_position), Color.WHITE, PUFF_SHOCKWAVE_RADIUS)
	captain.vanished.emit()
	captain.queue_free()
