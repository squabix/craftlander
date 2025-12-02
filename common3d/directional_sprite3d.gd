extends Sprite3D
class_name DirectionalSprite3D

@export var front_texture: Texture2D
@export var front_left_texture: Texture2D
@export var left_texture: Texture2D
@export var back_left_texture: Texture2D
@export var back_texture: Texture2D
@export var back_right_texture: Texture2D
@export var right_texture: Texture2D
@export var front_right_texture: Texture2D

@onready var direction_texture_map: Dictionary = {
	Vector3(0, 0, 1): front_texture,
	Vector3(0, 0, -1): back_texture,
	Vector3(-1, 0, 0): left_texture,
	Vector3(1, 0, 0): right_texture,
	
	Vector3(0.7, 0, 0.7): front_right_texture,
	Vector3(0.7, 0, -0.7): back_right_texture,
	Vector3(-0.7, 0, 0.7): front_left_texture,
	Vector3(-0.7, 0, -0.7): back_left_texture
}

func _ready() -> void:
	clear_null_mappings()

func clear_null_mappings() -> void:
	for direction in direction_texture_map.keys():
		if direction_texture_map[direction] == null:
			direction_texture_map.erase(direction)

func _process(_delta: float) -> void:
	update_texture()

func get_local_rotated_position(from: Vector3) -> Vector3:
	var local_cam_pos := from - global_position
	var camera_rotation := 0.0 # camera.global_rotation.y
	return local_cam_pos.rotated(Vector3.UP, global_rotation.y - camera_rotation)

func get_direction_to_camera(local_rotated_cam_position: Vector3) -> Vector3:
	return global_position.direction_to(local_rotated_cam_position + global_position)


func update_texture() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera):
		return
	
	var direction_to_camera: Vector3 = get_direction_to_camera(
		get_local_rotated_position(
			camera.global_position
		)
	)
	var best_texture: Texture2D
	var closest_distance := INF
	
	for direction in direction_texture_map:
		var distance := direction_to_camera.distance_to(direction)
		if distance < closest_distance:
			best_texture = direction_texture_map[direction]
			closest_distance = distance
	
	if best_texture == null:
		return
	
	texture = best_texture
