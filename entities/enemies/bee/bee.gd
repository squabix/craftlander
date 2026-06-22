extends Entity3D

const DAMAGE_AMOUNT := 1.0

const MIN_ATTACK_TIME := 0.3
const MAX_ATTACK_TIME := 0.6

const BASE_HEIGHT := 1.3
const HEIGHT_RANDOM_OFFSET := 0.3

const ATTACK_RANGE := 1.0

var target_healths: Dictionary[Node3D, Health] = {}

@export var sight: RadialSight3D
@export var hit_timer: Timer
@export var form_nodes: Array[Node3D]

func _ready() -> void:
	hit_timer.timeout.connect(_on_hit_timer_timeout)
	_start_random_timer()
	randomize_height()

func randomize_height() -> void:
	var height := BASE_HEIGHT + randf_range(-HEIGHT_RANDOM_OFFSET, HEIGHT_RANDOM_OFFSET)
	for node in form_nodes:
		node.position.y = height

func _start_random_timer() -> void:
	hit_timer.wait_time = randf_range(MIN_ATTACK_TIME, MAX_ATTACK_TIME)
	hit_timer.start()

func get_target_health() -> Health:
	return Util.find_stored_child_of_class(target_healths, sight.target)

func attack() -> void:
	
	# Target is out of range
	if global_position.distance_to(sight.target_position) > ATTACK_RANGE:
		return
	
	get_target_health().hurt(1.0)

func _on_hit_timer_timeout() -> void:
	attack()
	_start_random_timer()
