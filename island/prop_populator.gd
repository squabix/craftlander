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
@export var prop_spread := 0.0
@export var populate_on_ready := true

var rng := RandomNumberGenerator.new()
var props: Dictionary[Vector3, Node3D] = {}

func reset() -> void:
	for prop in props.values():
		Util.safe_free(prop)
	props = {}

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
	
	for prop in prop_quantities:
		var prop_count := 0
		while prop_count < prop_quantities[prop]:
			var point := get_random_point()
			var spawn_position := island_generator.get_pixel_position(point.x, point.y)
			
			# Position is too low
			if spawn_position.y < prop.min_height:
				continue
			
			# Position is too close to another point
			if not props.is_empty() and get_shortest_prop_distance(spawn_position) < prop_spread:
				continue
			
			# Already spawned at position
			if spawn_position in props:
				continue
			
			# Successfully add prop
			props[spawn_position] = add_prop(prop, point)
			prop_count += 1
	
	await get_tree().process_frame
	EventBus.trigger("island_populated")

func get_shortest_prop_distance(to: Vector3) -> float:
	var shortest_distance := INF
	for prop_position in props.keys():
		var distance := (prop_position as Vector3).distance_squared_to(to)
		if distance < shortest_distance:
			shortest_distance = distance
	return shortest_distance

func _ready() -> void:
	if not populate_on_ready:
		return
	await get_tree().process_frame
	populate()
