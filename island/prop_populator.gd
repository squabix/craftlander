@tool
class_name PropPopulator
extends Node3D

const PLACEMENT_STEP := Vector2i(2, 2)
const JITTER_AMOUNT := Vector2i(1, 1)

@export_tool_button("Populate", "TileMapDock")
var populate_tool_button := populate
@export_tool_button("Clear", "Reload")
var clear_tool_button := clear

@export var island_generator: HeightmapTerrainGenerator
@export var prop_quantities: Dictionary[IslandProp, int]
@export var populate_on_ready := true

var props: Dictionary[Vector3, Node3D] = { }
var prop_resources: Dictionary[Vector3, IslandProp] = { }


func _ready() -> void:
	EventBus.subscribe("island_terrain_generated", populate if populate_on_ready else EventBus.trigger.bind("island_populated"))


func clear() -> void:
	# Free all prop instances
	for prop in props.values():
		if not is_instance_valid(prop):
			continue
		prop.free()
	
	for child in get_children():
		if not is_instance_valid(child):
			continue
		child.free()

	# Clear prop dictionaries
	props = { }
	prop_resources = { }


func get_random_point() -> Vector2i:
	return Vector2i(
		randi_range(0, island_generator.map_resolution.x - 1),
		randi_range(0, island_generator.map_resolution.y - 1),
	)


func add_prop(prop: IslandProp, point: Vector2i, spawn_position: Vector3) -> Node3D:
	# Add instance
	var instance: Node3D = prop.scene.instantiate()
	add_child.call_deferred(instance)

	# Place/transform instance
	island_generator.place_node(instance, point.x, point.y, prop.normal_conformity)
	instance.rotation_degrees.y = randf() * 360.0
	instance.scale = Vector3.ONE * randf_range(prop.min_scale, prop.max_scale)
	
	# If running inside the editor, set the owner to the current scene root
	if Engine.is_editor_hint():
		instance.set.call_deferred("owner", get_tree().edited_scene_root)
		print("Set owner")
	
	# Assign prop instance in dictionaries
	props[spawn_position] = instance
	prop_resources[spawn_position] = prop

	return instance


func populate() -> void:
	clear()

	# Sort props by radius largest to smallest
	var sorted_props := prop_quantities.keys()
	sorted_props.sort_custom(
		func(a: IslandProp, b: IslandProp):
			return a.radius > b.radius
	)

	# Process each prop type independently
	for prop in sorted_props:
		var target_quantity := prop_quantities[prop]
		var spawned_count := 0

		# Gather every coordinate on the map where this prop can spawn
		var valid_points: Array[Vector2i] = []

		for x in range(0, island_generator.map_resolution.x, PLACEMENT_STEP.x):
			for y in range(0, island_generator.map_resolution.y, PLACEMENT_STEP.y):
				var pt := Vector2i(x, y)
				var pos := island_generator.get_pixel_position(pt.x, pt.y)

				if pos.y >= prop.min_height and pos.y <= prop.max_height:
					valid_points.append(pt)

		# Shuffle only the valid locations for this prop
		valid_points.shuffle()

		for point in valid_points:
			if spawned_count >= target_quantity:
				break # Met quota for this prop

			# Apply organic jitter
			var jittered_point := jitter_point(point)
			var spawn_position := island_generator.get_pixel_position(jittered_point.x, jittered_point.y)

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
			add_prop(prop, jittered_point, spawn_position)
			spawned_count += 1

	await get_tree().process_frame
	EventBus.trigger("island_populated")


func jitter_point(point: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(point.x + randi_range(-JITTER_AMOUNT.x, +JITTER_AMOUNT.x), 0, island_generator.map_resolution.x - 1),
		clampi(point.y + randi_range(-JITTER_AMOUNT.y, +JITTER_AMOUNT.y), 0, island_generator.map_resolution.y - 1),
	)


func avoids_intersecting_radii(radius: float, radius_position: Vector3) -> bool:
	for other_position in prop_resources.keys():
		var square_distance: float = Util.vec3to2(other_position, Util.VECTOR3Y).distance_squared_to(Util.vec3to2(radius_position, Util.VECTOR3Y))

		var other_radius := prop_resources[other_position].radius
		var min_required_distance := maxf(radius, other_radius)
		var square_radius := min_required_distance * min_required_distance

		if square_distance < square_radius:
			return false

	return true
