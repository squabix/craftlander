class_name IslandNavRegion
extends NavigationRegion3D

static var current: IslandNavRegion

@export var island_generator: HeightMapTerrainGenerator
@export var prop_populator: PropPopulator
@export var terrain: Node3D

var prop_geometry_cache: Dictionary[Node, NavigationMeshSourceGeometryData3D] = { }
var inverse_region_transform: Transform3D

# Geometries
var base_geometry: NavigationMeshSourceGeometryData3D
var active_baking_geometry: NavigationMeshSourceGeometryData3D

# Baking statuses
var has_baked := false
var is_region_baking := false
var is_bake_queued := false


static func transform_to_region_space(vertices: PackedFloat32Array, relative_transform: Transform3D) -> void:
	for i in range(0, vertices.size(), 3):
		var world_vertex := relative_transform * Vector3(vertices[i], vertices[i + 1], vertices[i + 2])
		vertices[i] = world_vertex.x
		vertices[i + 1] = world_vertex.y
		vertices[i + 2] = world_vertex.z


func _ready() -> void:
	current = self
	EventBus.subscribe("island_terrain_generated", reset)


func reset() -> void:
	if navigation_mesh == null:
		navigation_mesh = NavigationMesh.new()

	base_geometry = NavigationMeshSourceGeometryData3D.new()
	parse_geometry_data(base_geometry, terrain)

	if prop_geometry_cache.is_empty():
		initialize_prop_cache()


func connect_prop_removal(prop: Node) -> void:
	if prop.tree_exiting.is_connected(remove_prop):
		return
	prop.tree_exiting.connect(remove_prop.bind(prop))


func cache_prop(prop: Node) -> void:
	prop_geometry_cache[prop] = get_prop_geometry(prop)


func parse_geometry_data(geometry: NavigationMeshSourceGeometryData3D, root: Node) -> void:
	NavigationMeshGenerator.parse_source_geometry_data(navigation_mesh, geometry, root)


func get_prop_geometry(prop: Node3D) -> NavigationMeshSourceGeometryData3D:
	var geometry := NavigationMeshSourceGeometryData3D.new()
	parse_geometry_data(geometry, prop)

	# Reposition vertices to region space
	var vertices := geometry.get_vertices() # Flat Array of x, y, z floats
	transform_to_region_space(vertices, inverse_region_transform * prop.global_transform)
	geometry.set_vertices(vertices)

	return geometry


func bake_props() -> void:
	# Queue the new bake if busy
	if is_region_baking:
		is_bake_queued = true
		return

	is_region_baking = true

	# Merge all cached prop geometries into the base island geometry
	update_active_geometry()

	# Bake the new geometry
	NavigationServer3D.bake_from_source_geometry_data_async(
		navigation_mesh,
		active_baking_geometry,
		_complete_baking,
	)


func update_active_geometry() -> void:
	active_baking_geometry = base_geometry.duplicate()
	for prop_geom in prop_geometry_cache.values():
		active_baking_geometry.merge(prop_geom)


func initialize_prop_cache() -> void:
	prop_geometry_cache.clear()

	inverse_region_transform = global_transform.affine_inverse()

	for prop in prop_populator.get_children():
		if not prop is Node3D:
			continue
		cache_prop(prop)
		connect_prop_removal(prop)

	bake_props()


func remove_prop(prop: Node) -> void:
	if not prop_geometry_cache.has(prop):
		return
	prop_geometry_cache.erase(prop)
	bake_props()


func _complete_baking() -> void:
	navigation_mesh = navigation_mesh
	is_region_baking = false

	# Rebake if queued
	if is_bake_queued:
		is_bake_queued = false
		bake_props()
	elif not has_baked:
		has_baked = true
		EventBus.trigger("island_navigation_baked")
