class_name RigidItemPickup3D
extends RigidBody3D

const MIN_COLLISION_SIZE := 0.2 # m

@export var item_pickup_interactable: ItemPickup3D
@export var hurtbox: Hurtbox3D
@export var saved_item: Item:
	set(value):
		saved_item = value
		if has_interactable():
			item_pickup_interactable.item = value
			if _ready_started:
				_setup_visuals()

@export_group("Ground Recovery", "ground_recovery")
@export var ground_recovery_staggerer: IntervalStaggerer
@export_flags_3d_physics var ground_recovery_mask := 64
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var ground_recovery_ray_height := 50.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var ground_recovery_tolerance := 0.05
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var ground_recovery_lift := 0.3

var is_set_up := false
var _ready_started := false
var _visuals_generated := false


static func from_item(item: Item, scene: PackedScene) -> RigidItemPickup3D:
	if item == null:
		return
	var scene_instance := scene.instantiate() as RigidItemPickup3D
	if scene_instance == null:
		return
	scene_instance.saved_item = item
	return scene_instance


func _ready() -> void:
	_ready_started = true
	freeze = true
	if not is_instance_valid(item_pickup_interactable):
		return

	if saved_item != null:
		item_pickup_interactable.item = saved_item

	item_pickup_interactable.auto_generate_collision = false
	item_pickup_interactable.picked_up.connect(Util.safe_free.bind(self))

	_setup_visuals()

	await get_tree().physics_frame
	freeze = false
	await get_tree().physics_frame
	is_set_up = true
	recover_from_underground()


func has_interactable() -> bool:
	return is_instance_valid(item_pickup_interactable)


func enable_ground_recovery() -> void:
	ground_recovery_staggerer.disabled = false


func recover_from_underground() -> void:
	if freeze or not is_set_up or ground_recovery_staggerer.disabled:
		return

	var ground := get_ground_above()
	if not ground.is_empty():
		place_on_ground(ground.position)


func place_on_ground(point: Vector3) -> void:
	global_position = point + Vector3.UP * ground_recovery_lift
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func get_ground_above() -> Dictionary:
	var from := global_position + Vector3.UP * ground_recovery_ray_height
	var to := global_position + Vector3.UP * ground_recovery_tolerance
	var query := PhysicsRayQueryParameters3D.create(from, to, ground_recovery_mask, [get_rid()])
	query.hit_back_faces = false
	return get_world_3d().direct_space_state.intersect_ray(query)


func _setup_visuals() -> void:
	if _visuals_generated or not has_interactable() or item_pickup_interactable.item == null:
		return
	_visuals_generated = true

	item_pickup_interactable.update_visuals()
	item_pickup_interactable.generate_all_collision(item_pickup_interactable)
	item_pickup_interactable.update_tooltip()

	var collision_shape := add_bounds_collision()

	# Duplicate collision shape to hurtbox
	if hurtbox:
		var hurtbox_collision_duplicate: CollisionShape3D = collision_shape.duplicate()
		hurtbox.add_child(hurtbox_collision_duplicate)
		hurtbox_collision_duplicate.global_transform = collision_shape.global_transform


func add_bounds_collision() -> CollisionShape3D:
	var bounds := get_visuals_bounds()
	var box := BoxShape3D.new()
	box.size = bounds.size.max(Vector3.ONE * MIN_COLLISION_SIZE)

	var collision_shape := CollisionShape3D.new()
	collision_shape.shape = box
	add_child(collision_shape)
	collision_shape.position = bounds.get_center()
	return collision_shape


func get_visuals_bounds() -> AABB:
	var to_local := global_transform.affine_inverse()
	var bounds := AABB()
	var has_bounds := false

	for mesh_instance: MeshInstance3D in Util.find_children_of_class(item_pickup_interactable.visuals, &"MeshInstance3D", true):
		if mesh_instance.mesh == null:
			continue
		if not mesh_instance.visible and not item_pickup_interactable.generate_invisible_collision:
			continue

		var mesh_bounds := (to_local * mesh_instance.global_transform) * mesh_instance.get_aabb()
		bounds = bounds.merge(mesh_bounds) if has_bounds else mesh_bounds
		has_bounds = true

	return bounds
