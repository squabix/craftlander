extends Node3D
class_name EntityPopulator

const MIN_CAMERA_DISTANCE_SQUARED := 100.0
const MAX_CAMERA_DISTANCE_SQUARED := 10000000.0

@export var entity_quantities: Dictionary[IslandEntityResource, int]

var entities: Dictionary[IslandEntityResource, Array]

func _ready() -> void:
	for i in 3:
		await get_tree().process_frame
	populate(true)

func clear_invalid_entities() -> void:
	for entity_resource in entities:
		for entity in entities[entity_resource]:
			if is_instance_valid(entity):
				continue
			entities[entity_resource].erase(entity)

func get_missing_quantity(entity_resource: IslandEntityResource) -> int:
	clear_invalid_entities()
	var intended_quantity := entity_quantities[entity_resource]
	if entity_resource in entities:
		return max(0, intended_quantity - entities[entity_resource].size())
	return intended_quantity

func get_spawnpoint(allow_frustom: bool, min_height: float=0.0, max_height: float=1000.0) -> Vector3:
	var region := IslandNavRegion.current
	var point: Vector3
	var camera: Camera3D = get_viewport().get_camera_3d()
	while true:
		point = NavigationServer3D.region_get_random_point(region.get_region_rid(), 1, false)
		
		if point.y < min_height:
			continue # Too high
		if point.y > max_height:
			continue # Too low
		#if not allow_frustom and camera.is_position_in_frustum(point):
			#continue # In frustum
		
		var distance_squared := camera.global_position.distance_squared_to(point)
		if distance_squared > MAX_CAMERA_DISTANCE_SQUARED:
			continue # Too far from camera
		if distance_squared < MIN_CAMERA_DISTANCE_SQUARED:
			continue # Too close to camera
		break
	return point

func populate(allow_frustom := false) -> void:
	for entity_resource in entity_quantities:
		var quantity_to_spawn := get_missing_quantity(entity_resource)
		if quantity_to_spawn == 0:
			continue
		for i in quantity_to_spawn:
			var spawnpoint := get_spawnpoint(
				allow_frustom,
				entity_resource.min_height,
				entity_resource.max_height
			)
			var entity: Entity3D = entity_resource.scene.instantiate()
			add_child(entity)
			entity.global_position = spawnpoint
			if entity_resource in entities:
				entities[entity_resource].append(entity)
			else:
				entities[entity_resource] = [entity]
