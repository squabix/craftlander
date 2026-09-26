class_name GhostCannon
extends Spawner3D

const MAX_IN_FLIGHT := 3
const LANDING_ATTEMPTS := 10
const AIM_TIME := 1.3
const LIFETIME_BUFFER := 2.0

static var all_telegraphs: Array[PlanarTelegraph3D]

@export_group("Scenes")
@export var cannonball_scene: PackedScene
@export var telegraph_scene: PackedScene

@export_group("Components")
@export var damage: Damage
@export var interval_staggerer: IntervalStaggerer
@export var visuals: Node3D

@export_group("Aim", "aim")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var aim_apex_height := 16.0 # above the higher of launch and landing
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var aim_min_offset := 5.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var aim_max_offset := 14.0
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var aim_front_arc := 120.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var aim_telegraph_spacing := 10.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var aim_blast_radius := 3.5
@export_flags_3d_physics var aim_ground_mask := 4

var target: Node3D
var active := false
var is_aiming := false

var _gravity := 0.0
var _pending_plan: ArcPlan


func _ready() -> void:
	super()
	interval_staggerer.disabled = true

	var probe := cannonball_scene.instantiate() as Cannonball
	_gravity = probe.gravity_scale
	probe.free()


func set_active(to: bool) -> void:
	active = to
	interval_staggerer.disabled = not to
	if to:
		interval_staggerer.reset()


func set_fire_interval(seconds: float) -> void:
	interval_staggerer.base_interval = seconds
	interval_staggerer.reset()


func fire() -> void:
	if not active or is_aiming or not is_instance_valid(target) or Cannonball.in_flight >= MAX_IN_FLIGHT:
		return

	var plan := plan_arc(get_landing_point())
	is_aiming = true
	await aim_toward(plan)
	is_aiming = false
	if active:
		fire_arc(plan)


func aim_toward(plan: ArcPlan) -> void:
	if not is_instance_valid(visuals):
		return
	var local_direction := global_basis.inverse() * plan.velocity.normalized()
	var up := Vector3.UP if absf(local_direction.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	var wanted := Basis.looking_at(local_direction, up).get_rotation_quaternion()
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visuals, ^"quaternion", wanted, AIM_TIME)
	await tween.finished


func plan_arc(landing_point: Vector3) -> ArcPlan:
	var displacement := landing_point - global_position
	var peak := maxf(displacement.y, 0.0) + aim_apex_height
	return ArcPlan.new(landing_point, displacement, peak, _gravity)


func fire_arc(plan: ArcPlan, ignore_cap := false) -> void:
	if not ignore_cap and Cannonball.in_flight >= MAX_IN_FLIGHT:
		return
	_pending_plan = plan
	spawn()


func create_instance() -> Node3D:
	return cannonball_scene.instantiate()


func initialize_instance(instance: Node3D) -> void:
	super(instance)
	var ball := instance as Cannonball
	ball.damage = damage
	_pending_plan.update_ball(ball)
	ball.telegraph = add_telegraph()


func add_telegraph() -> DiscTelegraph3D:
	var telegraph := telegraph_scene.instantiate() as DiscTelegraph3D
	telegraph.radius = aim_blast_radius
	telegraph.fill_duration = _pending_plan.flight
	Spawner3D.root.add_child(telegraph)
	telegraph.global_position = _pending_plan.landing_point + Vector3.UP * 0.3
	all_telegraphs.append(telegraph)
	telegraph.tree_exited.connect(all_telegraphs.erase.bind(telegraph))
	return telegraph


func snap_to_ground(point: Vector3) -> Vector3:
	var from := point + Vector3.UP * 40.0
	var query := PhysicsRayQueryParameters3D.create(from, point + Vector3.DOWN * 80.0, aim_ground_mask)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position as Vector3 if not hit.is_empty() else point


func get_landing_point() -> Vector3:
	var best := target.global_position
	var best_clearance := -1.0
	var facing := get_facing()
	
	for attempt in LANDING_ATTEMPTS:
		var spread := deg_to_rad(randf_range(-aim_front_arc / 2.0, aim_front_arc / 2.0))
		var offset := facing.rotated(spread) * randf_range(aim_min_offset, aim_max_offset)
		var candidate := snap_to_ground(target.global_position + Vector3(offset.x, 0.0, offset.y))
		
		var clearance := get_telegraph_clearance(candidate)
		if clearance >= aim_telegraph_spacing:
			return candidate
		if clearance > best_clearance:
			best = candidate
			best_clearance = clearance
	
	return best


func get_facing() -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector2.UP
	var forward := -camera.global_basis.z
	var flat := Util.vec3to2(forward, Util.VECTOR3Y)
	return flat.normalized() if flat.length_squared() > 0.0001 else Vector2.UP


func get_telegraph_clearance(point: Vector3) -> float:
	var clearance := INF
	for telegraph in all_telegraphs:
		if not is_instance_valid(telegraph):
			continue
		var offset := (telegraph.global_position - point) * Vector3(1.0, 0.0, 1.0)
		clearance = minf(clearance, offset.length())
	return clearance


class ArcPlan:
	var landing_point := Vector3.ZERO
	var velocity := Vector3.ZERO
	var flight := 0.0

	func _init(landing: Vector3, displacement: Vector3, peak: float, gravity: float) -> void:
		landing_point = landing
		var rise_time := sqrt(2.0 * peak / gravity)
		var fall_time := sqrt(2.0 * (peak - displacement.y) / gravity)
		flight = rise_time + fall_time
		velocity = Vector3(displacement.x / flight, rise_time * gravity, displacement.z / flight)
	
	func update_ball(ball: Cannonball) -> void:
		ball.velocity = velocity
		ball.lifetime = flight + LIFETIME_BUFFER
