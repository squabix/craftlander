extends Entity3D

const DAMAGE_AMOUNT := 1.0

const RUN_THRESHOLD := 0.5
const WALK_THESHOLD := 0.3

const MIN_ATTACK_TIME := 0.3
const MAX_ATTACK_TIME := 0.6

@onready var sight: RadialSight3D = $Sight3D
@onready var hit_timer: Timer = $HitTimer

func _ready() -> void:
	hit_timer.timeout.connect(_on_hit_timer_timeout)
	_start_random_timer()

func _start_random_timer() -> void:
	hit_timer.wait_time = randf_range(MIN_ATTACK_TIME, MAX_ATTACK_TIME)
	hit_timer.start()

func attack() -> void:
	if global_position.distance_to(sight.target_position) <= 1.0:
		var attacked_health: Health = Util.find_child_of_class(sight.target, "Health")
		attacked_health.hurt(1.0)

func _on_hit_timer_timeout() -> void:
	attack()
	_start_random_timer()
