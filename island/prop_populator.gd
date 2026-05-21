@tool
extends Node3D
class_name PropPopulator

@export var island_generator: HeightmapTerrainGenerator
@export var prop_quantities: Dictionary[IslandProp, int]
@export var rng_seed := 0
@export var prop_spread := 0.0
@export var populate_on_ready := true
@export_tool_button("Populate")
var populate_tool_button := populate
@export_tool_button("Reset")
var reset_tool_button := reset

var props: Dictionary[Vector3, Node3D] = {}

func reset() -> void:
	for prop in props.values():
		Util.safe_free(prop)
	props = {}

func populate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	
	reset()
	
	for prop in prop_quantities:
		var prop_count := 0
		while prop_count < prop_quantities[prop]:
			var px := rng.randi_range(0, island_generator.map_resolution.x - 1)
			var py := rng.randi_range(0, island_generator.map_resolution.y - 1)
			var spawn_position := island_generator.get_pixel_position(px, py)
			
			if spawn_position in props:
				continue
			
			if spawn_position.y < prop.min_height:
				continue
			
			if not props.is_empty() and get_shortest_prop_distance(spawn_position) < prop_spread:
				continue
			
			var instance: Node3D = prop.scene.instantiate()
			add_child.call_deferred(instance)
			island_generator.place_node(instance, px, py, prop.normal_conformity)
			instance.rotation_degrees.y = rng.randf_range(0.0, 360.0)
			instance.scale = Vector3.ONE * rng.randf_range(prop.min_scale, prop.max_scale)
			props[spawn_position] = instance
			
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
