@tool
extends Node3D
class_name HeightmapTerrainGenerator

@export_tool_button("Update Mesh")
var update_texture_action: Callable = update_mesh

@export var map_size: Vector3
@export var map_resolution: Vector2i
@export var image_width: int
@export var image_height: int
@export var mesh_instance: MeshInstance3D
@export var collision_shape: CollisionShape3D
@export var generate_on_ready: bool = true

var mesh: PlaneMesh

func shader_set(parameter: String, to: Variant) -> void:
	mesh_instance.material_override.set_shader_parameter(
		parameter,
		to
	)

func add_new_mesh() -> void:
	mesh_instance.mesh = PlaneMesh.new()
	mesh_instance.mesh.size = Vector2(map_size.x, map_size.z)
	mesh_instance.mesh.subdivide_width = map_resolution.x
	mesh_instance.mesh.subdivide_depth = map_resolution.y
	mesh = mesh_instance.mesh

func _ready() -> void:
	if generate_on_ready:
		await get_tree().process_frame
		generate()

func generate() -> void:
	add_new_mesh()
	var image_texture: ImageTexture = update_shader_texture()
	update_collision_shape(image_texture)

func update_mesh() -> void:
	add_new_mesh()
	var image_texture: ImageTexture = update_shader_texture()

func update_shader_texture() -> ImageTexture:
	var image_texture: ImageTexture = generate_image_texture()
	shader_set("heightmap", image_texture)
	shader_set("max_height", map_size.y)
	mesh_instance.material_override.set_shader_parameter(
		"albedo_texture",
		image_texture
	)
	return image_texture

func update_collision_shape(image_texture: ImageTexture) -> void:
	var img: Image = image_texture.get_image()
	img.convert(Image.FORMAT_RF)
	var shape := HeightMapShape3D.new()
	shape.update_map_data_from_image(img, 0.0, map_size.y)
	collision_shape.shape = shape
	collision_shape.scale.x = mesh.size.x / img.get_width()
	collision_shape.scale.z = mesh.size.y / img.get_height()

func generate_image_texture() -> ImageTexture:
	return ImageTexture.create_from_image(
		Image.create_empty(
			image_width,
			image_height,
			false,
			Image.FORMAT_L8
		)
	)
