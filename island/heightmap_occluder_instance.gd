@tool
class_name HeightMapOccluderInstance
extends OccluderInstance3D

@export_tool_button("Generate", "ArrayOccluder3D") var generate_action := generate

@export var terrain_generator: HeightMapTerrainGenerator
@export_range(2, 32, 1, "suffix:px") var step_size := 4
@export var generate_on_ready := false


func _ready() -> void:
	if generate_on_ready:
		generate()


func generate() -> void:
	if not is_instance_valid(terrain_generator):
		Util.node_error("%s cannot generate occluder with invalid terrain generator %s", self, terrain_generator)
		return

	WorkerThreadPool.add_task(
		_bake_occluder_thread.bind(
			terrain_generator.map_resolution,
			terrain_generator.map_size,
			terrain_generator.heightmap_sampler,
			step_size,
		),
	)


func _get_decimated_pixels(resolution: int, step: int) -> PackedInt32Array:
	var pixels := PackedInt32Array()
	for pixel in range(0, resolution, step):
		pixels.append(pixel)
	if pixels[-1] != resolution - 1:
		pixels.append(resolution - 1)
	return pixels


func _bake_occluder_thread(map_resolution: Vector2i, map_size: Vector3, heightmap_sampler: Callable, decimation_step: int) -> void:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()

	var decimated_pixels_x := _get_decimated_pixels(map_resolution.x, decimation_step)
	var grid_width := decimated_pixels_x.size()
	var cell_pixel_ranges_x := _compute_cell_pixel_ranges(decimated_pixels_x, map_resolution.x)

	var decimated_pixels_y := _get_decimated_pixels(map_resolution.y, decimation_step)
	var grid_height := decimated_pixels_y.size()
	var cell_pixel_ranges_y := _compute_cell_pixel_ranges(decimated_pixels_y, map_resolution.y)

	# Build local vertex positions mirroring PlaneMesh spatial layout
	# Each vertex takes lowest sampled height across cell so decimated occluder surface never exceeds true terrain between sampled points
	for grid_row in grid_height:
		var pixel_y := decimated_pixels_y[grid_row]
		var cell_pixel_range_y := cell_pixel_ranges_y[grid_row]
		for grid_column in grid_width:
			var pixel_x := decimated_pixels_x[grid_column]
			var cell_pixel_range_x := cell_pixel_ranges_x[grid_column]

			var lowest_sampled_height := 1.0
			for sample_pixel_y in range(cell_pixel_range_y.x, cell_pixel_range_y.y + 1):
				for sample_pixel_x in range(cell_pixel_range_x.x, cell_pixel_range_x.y + 1):
					lowest_sampled_height = minf(lowest_sampled_height, heightmap_sampler.call(sample_pixel_x, sample_pixel_y))

			var vertex_local_x := (float(pixel_x) / float(map_resolution.x - 1)) * map_size.x - map_size.x / 2.0
			var vertex_local_y := lowest_sampled_height * map_size.y
			var vertex_local_z := (float(pixel_y) / float(map_resolution.y - 1)) * map_size.z - map_size.z / 2.0

			vertices.append(Vector3(vertex_local_x, vertex_local_y, vertex_local_z))

	# Map structural triangulation indices
	for grid_row in grid_height - 1:
		for grid_col in grid_width - 1:
			var near_row_start := grid_row * grid_width
			var far_row_start := (grid_row + 1) * grid_width

			var near_left := near_row_start + grid_col
			var near_right := near_row_start + grid_col + 1
			var far_left := far_row_start + grid_col
			var far_right := far_row_start + grid_col + 1

			# Triangle 1 (Standard facing-up winding order)
			indices.append(near_left)
			indices.append(far_left)
			indices.append(near_right)

			# Triangle 2 (Standard facing-up winding order)
			indices.append(near_right)
			indices.append(far_left)
			indices.append(far_right)

	_finalize_occluder.call_deferred(vertices, indices)


func _compute_cell_pixel_ranges(decimated_pixels: PackedInt32Array, axis_resolution: int) -> Array[Vector2i]:
	var cell_pixel_ranges: Array[Vector2i] = []
	for grid_index in decimated_pixels.size():
		var is_first := grid_index == 0
		var is_last := grid_index == decimated_pixels.size() - 1

		var cell_pixel_start := 0 if is_first else (decimated_pixels[grid_index - 1] + decimated_pixels[grid_index]) / 2 + 1
		var cell_pixel_end := axis_resolution - 1 if is_last else (decimated_pixels[grid_index] + decimated_pixels[grid_index + 1]) / 2

		cell_pixel_ranges.append(Vector2i(cell_pixel_start, cell_pixel_end))
	return cell_pixel_ranges


func _finalize_occluder(vertices: PackedVector3Array, indices: PackedInt32Array) -> void:
	var array_occluder := ArrayOccluder3D.new()
	array_occluder.set_arrays(vertices, indices)
	occluder = array_occluder
