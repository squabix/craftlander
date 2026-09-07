extends Entity3D

const BASE_HEIGHT := 1.0
const HEIGHT_RANDOM_OFFSET := 0.3

@export var attack_ray: HitRay3D
@export var form_nodes: Array[Node3D]

func _ready() -> void:
	randomize_height()
	if attack_ray and attack_ray.damage:
		attack_ray.damage.source = self

func randomize_height() -> void:
	var height := BASE_HEIGHT + randf_range(-HEIGHT_RANDOM_OFFSET, HEIGHT_RANDOM_OFFSET)
	for node in form_nodes:
		node.position.y = height
