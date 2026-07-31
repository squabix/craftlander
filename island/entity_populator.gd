class_name EntityPopulator
extends Node3D

const MAX_SPAWN_POSITION_ATTEMPTS_PER_FRAME := 64
const MIN_CAMERA_DISTANCE_SQUARED := 100.0
const MAX_CAMERA_DISTANCE_SQUARED := INF

@export var entity_quantities: Dictionary[IslandEntityResource, int]
@export var repopulate_timer: Timer
@export var disabled := false

var entities: Dictionary[IslandEntityResource, Array]
var has_populated := false


func _ready() -> void:
	EventBus.subscribe(&"island_navigation_baked", populate)


func clear_invalid_entities() -> void:
	for entity_resource in entities:
		for entity in entities[entity_resource]:
			if is_instance_valid(entity):
				continue
			entities[entity_resource].erase(entity)


func get_missing_quantity(entity_resource: IslandEntityResource) -> int:
	clear_invalid_entities()
	var intended_quantity: int = entity_quantities.get(entity_resource, 0)
	return max(0, intended_quantity - get_current_quantity(entity_resource))


func get_current_quantity(entity_resource: IslandEntityResource):
	if entity_resource == null or not entity_resource in entities:
		return 0
	return entities[entity_resource].size()


func get_random_point(rid: RID) -> Vector3:
	return NavigationServer3D.region_get_random_point(rid, 1, false)


func get_spawnpoint(min_height: float, max_height: float, allow_in_frustum: bool) -> Vector3:
	var rid := IslandNavRegion.current.get_rid()
	if not rid.is_valid():
		push_error("%s cannot get spawnpoint with invalid RID: %s" % [self, rid])
		return Vector3.ZERO
	
	var viewport := get_viewport()
	if not is_instance_valid(viewport):
		push_error("%s cannot get spawnpoint with invalid viewport: %s" % [self, viewport])
		return Vector3.ZERO
	
	var camera := viewport.get_camera_3d()
	if not is_instance_valid(camera):
		push_error("%s cannot get spawnpoint with invalid camera: %s" % [self, camera])
		return Vector3.ZERO
	
	var point: Vector3
	var attempts := 0
	
	while attempts < MAX_SPAWN_POSITION_ATTEMPTS_PER_FRAME:
		attempts += 1
		point = get_random_point(rid)

		if point == Vector3.ZERO:
			break # NavigationServer3D failed

		if point.y < min_height:
			continue # Too low
		if point.y > max_height:
			continue # Too high
		
		if not allow_in_frustum and camera and camera.is_position_in_frustum(point):
			continue # In frustum

		var distance_squared := camera.global_position.distance_squared_to(point) if camera else 999999.0
		if distance_squared > MAX_CAMERA_DISTANCE_SQUARED:
			continue # Too far from camera
		if distance_squared < MIN_CAMERA_DISTANCE_SQUARED:
			continue # Too close to camera
		
		return point # Found a valid point!
	
	# If ran out of attempts this frame, wait to try again next frame
	await get_tree().physics_frame
	return await get_spawnpoint(min_height, max_height, allow_in_frustum)


func add_entity(entity_resource: IslandEntityResource, spawnpoint := Vector3.ZERO, allow_in_frustum := false) -> Entity3D:
	if spawnpoint == Vector3.ZERO:
		spawnpoint = await get_spawnpoint(entity_resource.min_height, entity_resource.max_height, allow_in_frustum)
	
	var entity: Entity3D = entity_resource.scene.instantiate()
	add_child(entity)
	entity.global_position = spawnpoint
	
	if entity_resource in entities:
		entities[entity_resource].append(entity)
	else:
		entities[entity_resource] = [entity]
	
	return entity


func initialize_repopulate_timer() -> bool:
	if not is_instance_valid(repopulate_timer):
		return false
	repopulate_timer.timeout.connect(populate.bind(false))
	repopulate_timer.start()
	return true


func populate(allow_in_frustum := false) -> void:
	if disabled:
		return
	
	# First populate
	if not has_populated:
		has_populated = true
		populate(true) # First populate allows spawning in sight of the player
		initialize_repopulate_timer()
		return
	
	# Subsequent populates
	for entity_resource in entity_quantities:
		for i in get_missing_quantity(entity_resource):
			add_entity(entity_resource, Vector3.ZERO, allow_in_frustum)
