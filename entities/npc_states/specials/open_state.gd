class_name OpenState
extends SequenceState

const STEAM_HEIGHT := 0.6
const STEAM_RADIUS := 0.7
const STEAM_FADE_TIME := 0.3

@export var next_state := &"Chasing"
@export var color := Color(0.3, 0.9, 1.0)
@export var damage_multiplier := 1.5

var duration := 0.0

var enemy: Enemy3D:
	get:
		return root as Enemy3D


func run() -> void:
	begin_open()
	var steam := EnemyVfx.aura(enemy, enemy.global_position + Vector3.UP * STEAM_HEIGHT, color, STEAM_RADIUS)

	var alive := await wait(duration * enemy.recovery_scale())
	steam.fade_out(STEAM_FADE_TIME)
	end_open()
	if not alive:
		return

	settle()
	go_to(next_state)


func exit() -> void:
	enemy.get_health().hurt_multiplier = 1.0


func begin_open() -> void:
	enemy.get_health().hurt_multiplier = damage_multiplier
	enemy.unlock_facing()


func end_open() -> void:
	enemy.get_health().hurt_multiplier = 1.0


func settle() -> void:
	pass
