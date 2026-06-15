@tool
extends Node3D
class_name PropPopulator

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
var props: Dictionary[Vector3, Node3D] = {}
var prop_resources: Dictionary[Vector3, IslandProp] = {}

func reset() -> void:
	for prop in props.values():
		Util.safe_free(prop)
	props = {}
	prop_resources = {} # Clear the resource registry

func get_random_point() -> Vector2i:
	return Vector2i(
		rng.randi_range(0, island_generator.map_resolution.x - 1),
		rng.randi_range(0, island_generator.map_resolution.y - 1)
	)

func add_prop(prop: IslandProp, point: Vector2i) -> Node3D:
	var instance: Node3D = prop.scene.instantiate()
	add_child.call_deferred(instance)
	island_generator.place_node(instance, point.x, point.y, prop.normal_conformity)
	instance.rotation_degrees.y = rng.randf_range(0.0, 360.0)
	instance.scale = Vector3.ONE * rng.randf_range(prop.min_scale, prop.max_scale)
	return instance

func populate() -> void:
	rng.seed = rng_seed
	
	reset()
	
	var sorted_props := prop_quantities.keys()
	sorted_props.sort_custom(func(a: IslandProp, b: IslandProp):
		return a.radius > b.radius
	)
	
	for prop in sorted_props:
		var prop_count := 0
		var attempts := 0
		var max_attempts := prop_quantities[prop] * max_attempts_per_prop
		
		while prop_count < prop_quantities[prop] and attempts < max_attempts:
			attempts += 1
			var point := get_random_point()
			var spawn_position := island_generator.get_pixel_position(point.x, point.y)
			
			# Position is outside height bounds (Fixed: now also checks max_height)
			if spawn_position.y < prop.min_height or spawn_position.y > prop.max_height:
				continue
			
			# Already spawned at this exact position
			if spawn_position in props:
				continue
			
			# Check custom radius constraints against already placed props
			if not is_position_valid(spawn_position, prop):
				continue
			
			# Successfully add prop
			props[spawn_position] = add_prop(prop, point)
			prop_resources[spawn_position] = prop # Track the resource type
			prop_count += 1
	
	await get_tree().process_frame
	EventBus.trigger("island_populated")

func is_position_valid(spawn_position: Vector3, new_prop: IslandProp) -> bool:
	for placed_pos in prop_resources.keys():
		var placed_prop := prop_resources[placed_pos]
		var distance_squared: float = placed_pos.distance_squared_to(spawn_position)

		var avoidance_radius := maxf(placed_prop.radius, new_prop.radius)
		
		if distance_squared < avoidance_radius * avoidance_radius:
			return false
	return true

func _ready() -> void:
	if Engine.is_editor_hint() or not populate_on_ready:
		return
	await get_tree().process_frame
	populate()
