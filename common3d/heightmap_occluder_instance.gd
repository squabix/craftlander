@tool
class_name HeightMapOccluderInstance
extends OccluderInstance3D

@export_tool_button("Generate", "ArrayOccluder3D") var generate_action := generate

@export var terrain_generator: HeightMapTerrainGenerator
@export_range(2, 32, 1, "suffix:px") var step_size := 4
@export var generate_on_ready := true


func _ready() -> void:
	if generate_on_ready:
		EventBus.subscribe(&"island_terrain_generated", generate)


func generate() -> void:
	assert(
			is_instance_valid(terrain_generator),
			"%s cannot generate occluder with invalid terrain generator %s" % [self, terrain_generator]
	)
	assert(
		not terrain_generator.heightmap_sampler.is_null(),
		"%s cannot generate occluder with null heightmap sampler from %s" % [self, terrain_generator]
	)

	WorkerThreadPool.add_task(
			_bake_occluder_thread.bind(
					terrain_generator.map_resolution,
					terrain_generator.map_size,
					terrain_generator.heightmap_sampler,
					step_size
			)
	)

func _bake_occluder_thread(map_resolution: Vector2i, map_size: Vector3, sample_callable: Callable, step: int) -> void:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()

	var x_coords := PackedInt32Array()
	var y_coords := PackedInt32Array()

	for x in range(0, map_resolution.x, step):
		x_coords.append(x)
	if x_coords[-1] != map_resolution.x - 1:
		x_coords.append(map_resolution.x - 1)

	for y in range(0, map_resolution.y, step):
		y_coords.append(y)
	if y_coords[-1] != map_resolution.y - 1:
		y_coords.append(map_resolution.y - 1)

	var grid_w := x_coords.size()
	var grid_h := y_coords.size()

	# Build local vertex positions mirroring PlaneMesh spatial layout
	for y_idx in grid_h:
		var y := y_coords[y_idx]
		for x_idx in grid_w:
			var x := x_coords[x_idx]
			
			var l_x := (float(x) / float(map_resolution.x - 1)) * map_size.x - map_size.x / 2.0
			var l_y: float = sample_callable.call(x, y) * map_size.y
			var l_z := (float(y) / float(map_resolution.y - 1)) * map_size.z - map_size.z / 2.0

			vertices.append(Vector3(l_x, l_y, l_z))

	# Map structural triangulation indices
	for y in grid_h - 1:
		for x in grid_w - 1:
			var row1 := y * grid_w
			var row2 := (y + 1) * grid_w

			var v00 := row1 + x
			var v10 := row1 + x + 1
			var v01 := row2 + x
			var v11 := row2 + x + 1

			# Triangle 1 (Standard facing-up winding order)
			indices.append(v00)
			indices.append(v01)
			indices.append(v10)

			# Triangle 2 (Standard facing-up winding order)
			indices.append(v10)
			indices.append(v01)
			indices.append(v11)

	_finalize_occluder.call_deferred(vertices, indices)


func _finalize_occluder(vertices: PackedVector3Array, indices: PackedInt32Array) -> void:
	var array_occluder := ArrayOccluder3D.new()
	array_occluder.set_arrays(vertices, indices)
	occluder = array_occluder
