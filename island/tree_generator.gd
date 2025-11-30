@tool
extends Node3D
class_name TreeGenerator

@export var island_generator: HeightmapTerrainGenerator
@export var tree_count: int
@export var min_tree_y: float
@export var min_tree_scale: float = 1.0
@export var max_tree_scale: float = 1.0
@export var seed: int
@export_tool_button("Regenerate Trees")
var regenerate_trees_tool_button: Callable = regenerate_trees

var trees: Dictionary[Vector3, TreeResource] = {}

@onready var tree_scene: PackedScene = preload("res://destructable_resource/tree.tscn")

func regenerate_trees() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	
	for tree in trees.values():
		tree.queue_free()
	trees = {}
	
	while trees.size() < tree_count:
		var px: int = rng.randi_range(0, island_generator.map_resolution.x)
		var py: int = rng.randi_range(0, island_generator.map_resolution.y)
		var spawn_position := island_generator.get_pixel_position(px, py)
		
		if spawn_position.y < min_tree_y:
			continue
		
		var new_tree: TreeResource = tree_scene.instantiate()
		add_child(new_tree)
		island_generator.place_node(new_tree, px, py)
		new_tree.rotation_degrees.y = rng.randf_range(0.0, 360.0)
		new_tree.scale = Vector3.ONE * rng.randf_range(min_tree_scale, max_tree_scale)
		trees[spawn_position] = new_tree

func _ready() -> void:
	await get_tree().process_frame
	print("Updated")
	regenerate_trees()
