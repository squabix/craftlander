extends Enemy3D

const BASE_HEIGHT := 1.0
const HEIGHT_RANDOM_OFFSET := 0.3

@export var form_nodes: Array[Node3D]

func _ready() -> void:
	super()
	randomize_height()

func randomize_height() -> void:
	var height := BASE_HEIGHT + randf_range(-HEIGHT_RANDOM_OFFSET, HEIGHT_RANDOM_OFFSET)
	for node in form_nodes:
		node.position.y = height
