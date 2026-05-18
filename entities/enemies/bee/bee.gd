extends Entity3D

const DAMAGE_AMOUNT := 1.0

const RUN_THRESHOLD := 0.5
const WALK_THESHOLD := 0.3

const MIN_ATTACK_TIME := 0.3
const MAX_ATTACK_TIME := 0.6

const ATTACK_RANGE := 1.0

var target_healths: Dictionary[Node3D, Health] = {}

@onready var sight: RadialSight3D = $Sight3D
@onready var hit_timer: Timer = $HitTimer

func _ready() -> void:
	hit_timer.timeout.connect(_on_hit_timer_timeout)
	_start_random_timer()

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
