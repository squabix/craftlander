@tool
extends Node3D
class_name PropPopulator

@export var island_generator: HeightmapTerrainGenerator
@export var prop_quantities: Dictionary[IslandProp, int]
@export var rng_seed: int
@export var prop_spread: float
@export_tool_button("Populate")
var populate_tool_button: Callable = populate
@export_tool_button("Reset")
var reset_tool_button: Callable = reset

var props: Dictionary[Vector3, Node3D] = {}

func reset() -> void:
	for prop in props.values():
		prop.queue_free()
	props = {}

func populate() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = rng_seed
	
	reset()
	
	for prop in prop_quantities:
		var prop_count: int = 0
		while prop_count < prop_quantities[prop]:
			var px: int = rng.randi_range(0, island_generator.map_resolution.x)
			var py: int = rng.randi_range(0, island_generator.map_resolution.y)
			var spawn_position := island_generator.get_pixel_position(px, py)
			
			if spawn_position in props:
				continue
			
			if spawn_position.y < prop.min_height:
				continue
			
			if not props.is_empty() and get_shortest_prop_distance(spawn_position) < prop_spread:
				continue
			
			var instance: Node3D = prop.scene.instantiate()
			add_child(instance)
			island_generator.place_node(instance, px, py)
			instance.rotation_degrees = instance.rotation_degrees.lerp(Vector3.ZERO, 1.0 - prop.normal_conformity)
			instance.rotation_degrees.y = rng.randf_range(0.0, 360.0)
			instance.scale = Vector3.ONE * rng.randf_range(prop.min_scale, prop.max_scale)
			props[spawn_position] = instance
			
			prop_count += 1

func get_shortest_prop_distance(to: Vector3) -> float:
	var shortest_distance := INF
	for prop_position in props.keys():
		var distance := (prop_position as Vector3).distance_squared_to(to)
		if distance < shortest_distance:
			shortest_distance = distance
	return shortest_distance

func _ready() -> void:
	await get_tree().process_frame
	print("Updated")
	populate()
