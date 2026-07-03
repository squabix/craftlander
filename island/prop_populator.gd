@tool
class_name PropPopulator
extends Node3D

@export_tool_button("Populate")
var populate_tool_button := populate
@export_tool_button("Reset")
var reset_tool_button := reset

@export var island_generator: HeightmapTerrainGenerator
@export var prop_quantities: Dictionary[IslandProp, int]
@export var rng_seed := 0
@export var populate_on_ready := true
@export var max_attempts_per_prop := 16

var rng := RandomNumberGenerator.new()
var props: Dictionary[Vector3, Node3D] = { }
var prop_resources: Dictionary[Vector3, IslandProp] = { }


func _ready() -> void:
	if not Engine.is_editor_hint() and not populate_on_ready:
		return
	EventBus.subscribe("island_terrain_generated", populate)


func reset() -> void:
	# Free all prop instances
	for prop in props.values():
		Util.safe_free(prop)

	# Clear prop dictionaries
	props = { }
	prop_resources = { }


func get_random_point() -> Vector2i:
	return Vector2i(
		rng.randi_range(0, island_generator.map_resolution.x - 1),
		rng.randi_range(0, island_generator.map_resolution.y - 1),
	)


func add_prop(prop: IslandProp, point: Vector2i, spawn_position: Vector3) -> Node3D:
	# Add instance
	var instance: Node3D = prop.scene.instantiate()
	add_child.call_deferred(instance)
	
	# Place/transform instance
	island_generator.place_node(instance, point.x, point.y, prop.normal_conformity)
	instance.rotation_degrees.y = rng.randf_range(0.0, 360.0)
	instance.scale = Vector3.ONE * rng.randf_range(prop.min_scale, prop.max_scale)

	# Assign prop instance in dictionaries
	props[spawn_position] = instance
	prop_resources[spawn_position] = prop

	return instance


func populate() -> void:
	rng.seed = rng_seed
	reset()

	var sorted_props := prop_quantities.keys()
	sorted_props.sort_custom(
		func(a: IslandProp, b: IslandProp):
			return a.radius > b.radius
	)

	for prop in sorted_props:
		var prop_count := 0
		var attempts := 0
		var max_attempts := prop_quantities[prop] * max_attempts_per_prop

		while prop_count < prop_quantities[prop]:
			if attempts >= max_attempts:
				break

			attempts += 1
			var point := get_random_point()
			var spawn_position := island_generator.get_pixel_position(point.x, point.y)
			
			# Position is outside height bounds
			if spawn_position.y < prop.min_height or spawn_position.y > prop.max_height:
				continue
			
			# Already spawned at this exact position
			if spawn_position in props:
				continue

			# Check custom radius constraints against already placed props
			if not avoids_intersecting_radii(prop.radius, spawn_position):
				continue
			
			# Successfully add prop
			add_prop(prop, point, spawn_position)
			prop_count += 1

	await get_tree().process_frame
	EventBus.trigger("island_populated")


func avoids_intersecting_radii(radius: float, radius_position: Vector3) -> bool:
	for other_position in prop_resources.keys():
		var square_distance: float = Util.vec3to2(other_position, Util.VECTOR3Y).distance_squared_to(Util.vec3to2(radius_position, Util.VECTOR3Y))

		var other_radius := prop_resources[other_position].radius
		var min_required_distance := maxf(radius, other_radius)
		var square_radius := min_required_distance * min_required_distance

		if square_distance < square_radius:
			return false
	
	return true
