class_name Enemy3D
extends Entity3D

signal swung
signal fired
signal teleported

const TURN_DEADZONE_SQUARED := 0.001

@export var anim_tree: AnimationTree
@export var anim_player: AnimationPlayer
@export var health: Health
@export var culling_controller: CullingController3D
@export var attack_ray: HitRay3D
@export var sight: RadialSight3D
@export var visuals: Node3D

@export_group("Locomotion Animation", "locomotion")
@export var locomotion_blend_parameter := &"parameters/RunBlendSpace/blend_position"

@export_group("Specials", "special")
@export_custom(PROPERTY_HINT_NONE, "suffix:rad/s") var special_turn_speed := 8.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var special_charge_height := 1.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var special_charge_radius := 0.6
@export var special_poses := false

@export_group("Terrain", "terrain")
@export_flags_3d_physics var terrain_ground_mask := 64
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var terrain_water_level := 0.8

var animate_locomotion := true
var base_scale := Vector3.ONE

var _pose_tween: Tween
var _played_shots: Array[StringName] = []


func _ready() -> void:
	super()
	if is_instance_valid(health):
		health.died.connect(_on_died)
	if is_instance_valid(attack_ray) and attack_ray.damage:
		attack_ray.damage.source = self
	if is_instance_valid(visuals):
		base_scale = visuals.scale

	# Wait two frames so held items exist before the visibility range is measured
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(culling_controller):
		culling_controller.update_visibility_range()


func _process(_delta: float) -> void:
	if animate_locomotion and is_instance_valid(anim_tree):
		anim_tree.set(locomotion_blend_parameter, get_planar_speed() / move_mode.max_speed.x)


func get_health() -> Health:
	return health if is_instance_valid(health) else Health.search(self)


func get_target() -> Node3D:
	return sight.target if is_instance_valid(sight) else null


func distance_to_target() -> float:
	var target := get_target()
	if not is_instance_valid(target):
		return INF

	var offset := global_position - target.global_position
	offset.y = 0.0
	return offset.length()


func get_yaw_to(point: Vector3) -> float:
	return Util.direction_yaw(point - global_position)


func aim_toward(point: Vector3, delta: float, snap: bool) -> void:
	var flat := point - global_position
	flat.y = 0.0
	if flat.length_squared() < TURN_DEADZONE_SQUARED:
		return

	if snap:
		global_rotation.y = get_yaw_to(point)
		return

	var step := special_turn_speed * delta
	global_rotation.y += clampf(angle_difference(global_rotation.y, get_yaw_to(point)), -step, step)


func lock_facing() -> void:
	pass


func unlock_facing() -> void:
	pass


func tell_time(base_seconds: float) -> float:
	return base_seconds


func recovery_scale() -> float:
	return 1.0


func say(_line: StringName) -> void:
	pass


func announce_attack(color: Color, tell_seconds: float) -> void:
	var charge := EnemyVfx.charge(self, global_position + Vector3.UP * special_charge_height, color, special_charge_radius)
	get_tree().create_timer(tell_seconds, false).timeout.connect(charge.fade_out.bind(0.15))


func vanish() -> void:
	visuals.visible = false
	get_health().invulnerable = true


func appear() -> void:
	visuals.visible = true
	get_health().invulnerable = false


func is_dry(point: Vector3) -> bool:
	return point.y > terrain_water_level


func ground(point: Vector3) -> Vector3:
	return Util.ground_point(get_world_3d(), point, terrain_ground_mask)


func pick_land_point(center: Vector3, min_distance: float, max_distance: float, base_angle: float, spread: float) -> Vector3:
	return Util.pick_land_point(get_world_3d(), center, min_distance, max_distance, base_angle, spread, terrain_ground_mask, terrain_water_level)


func pose(rotation_x: float, scale_y: float, duration: float) -> void:
	if not is_instance_valid(visuals):
		return
	if _pose_tween != null:
		_pose_tween.kill()

	_pose_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_pose_tween.tween_property(visuals, ^"rotation:x", rotation_x, duration)
	_pose_tween.tween_property(visuals, ^"scale:y", base_scale.y * scale_y, duration)


func play_animation(one_shot: StringName) -> void:
	if one_shot == &"" or not is_instance_valid(anim_tree):
		return

	stop_other_animations(one_shot)
	if not _played_shots.has(one_shot):
		_played_shots.append(one_shot)

	anim_tree.set("parameters/%s/request" % one_shot, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func stop_other_animations(one_shot: StringName) -> void:
	for other in _played_shots:
		if other != one_shot:
			stop_animation(other)


func stop_animation(one_shot: StringName) -> void:
	if one_shot != &"" and is_instance_valid(anim_tree) and anim_tree.get("parameters/%s/active" % one_shot):
		anim_tree.set("parameters/%s/request" % one_shot, AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)


func play_player_animation(animation: StringName) -> void:
	if animation == &"" or not is_instance_valid(anim_player):
		return

	if is_instance_valid(anim_tree):
		anim_tree.active = false
	anim_player.active = true
	anim_player.play(animation)
	if not anim_player.animation_finished.is_connected(_on_player_animation_finished):
		anim_player.animation_finished.connect(_on_player_animation_finished, CONNECT_ONE_SHOT)


func _on_player_animation_finished(_animation: StringName) -> void:
	anim_player.active = false
	if is_instance_valid(anim_tree):
		anim_tree.active = true


func _on_died() -> void:
	set_physics_process(false)
	if is_instance_valid(anim_tree):
		anim_tree.active = false
	if is_instance_valid(anim_player):
		anim_player.active = false
	Util.safe_free(self)
