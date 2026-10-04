class_name GhostCaptain
extends Enemy3D

signal phase_changed(phase: int)
signal vanished

const PHASE_COLORS: Array[Color] = [Color(0.6, 0.8, 1.0), Color(1.0, 0.6, 0.2), Color(1.0, 0.15, 0.1)]

const AURA_HEIGHT := 0.4
const AURA_RADIUS := 1.1
const AURA_TINT_TIME := 0.4
const AURA_BASE_INTENSITY := 0.5
const AURA_INTENSITY_PER_PHASE := 0.25

const SPAWN_BURST_HEIGHT := 1.2
const CHARGE_HEIGHT := 1.4
const CHARGE_FADE_TIME := 0.15

@export var brain: StateMachine
@export var tell_light: OmniLight3D
@export var beacon: MeshInstance3D
@export var cannon_aim: GhostCaptainCannonAim
@export var voice: LinePlayer3D

@export_group("Phases", "phase")
@export var phase_thresholds: Array[float] = [0.7, 0.4] # health ratios that start phases two and three

@export_group("Tempo", "tempo")
@export var tempo_approach_speeds: Array[float] = [5.5, 6.5, 7.5] # m/s per phase
@export var tempo_tell_scales: Array[float] = [1.0, 0.85, 0.7]
@export var tempo_recovery_scales: Array[float] = [1.0, 0.8, 0.6]

@export_group("Readability", "read")
@export var read_aura_energy := 2.5
@export var read_tell_energy := 14.0

var phase := 0
var facing_locked := false

var _light_tween: Tween
var _aura: AdjustableParticles3D


func _ready() -> void:
	super()
	
	move_mode = move_mode.duplicate() as MoveMode
	apply_phase_look()
	
	_create_aura.call_deferred()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _physics_process(delta: float) -> void:
	super(delta)
	if not facing_locked and not health.dead:
		turn_toward_player(delta)


func get_player() -> Player:
	return sight.target as Player


func turn_toward_player(delta: float) -> void:
	var player := get_player()
	if player != null:
		super.aim_toward(player.global_position, delta, false)


func aim_toward(point: Vector3, delta: float, snap: bool) -> void:
	if snap:
		super(point, delta, true)


func say(line: StringName) -> void:
	voice.say(line)


func lock_facing() -> void:
	facing_locked = true


func unlock_facing() -> void:
	facing_locked = false


func tell_time(base_seconds: float) -> float:
	return base_seconds * tempo_tell_scales[phase]


func recovery_scale() -> float:
	return tempo_recovery_scales[phase]


func get_due_phase() -> int:
	var ratio := health.hp / health.max_hp
	var due := 0

	for threshold in phase_thresholds:
		if ratio <= threshold:
			due += 1

	return due


func is_phase_due() -> bool:
	return get_due_phase() > phase


func set_phase(to: int) -> void:
	phase = to
	phase_changed.emit(phase)


func apply_phase_look() -> void:
	set_speed(tempo_approach_speeds[phase])
	set_light(PHASE_COLORS[phase], read_aura_energy)
	tint_aura()
	tint_beacon()


func tint_aura() -> void:
	if is_instance_valid(_aura):
		_aura.tween_tint(PHASE_COLORS[phase], AURA_TINT_TIME)
		_aura.set_intensity(AURA_BASE_INTENSITY + AURA_INTENSITY_PER_PHASE * phase)


func tint_beacon() -> void:
	if is_instance_valid(beacon):
		(beacon.material_override as StandardMaterial3D).albedo_color = PHASE_COLORS[phase]


func announce_attack(color: Color, tell_seconds: float) -> void:
	start_charge(color, tell_seconds)
	set_light(color, read_aura_energy)
	brighten_light(tell_seconds)


func start_charge(color: Color, tell_seconds: float) -> void:
	var charge := EnemyVfx.charge(self, global_position + Vector3.UP * CHARGE_HEIGHT, color, tell_seconds)
	get_tree().create_timer(tell_seconds, false).timeout.connect(charge.fade_out.bind(CHARGE_FADE_TIME))


func brighten_light(duration: float) -> void:
	if _light_tween != null:
		_light_tween.kill()

	_light_tween = create_tween()
	_light_tween.tween_property(tell_light, ^"light_energy", read_tell_energy, duration)


func vanish() -> void:
	visuals.visible = false
	health.invulnerable = true
	health.intangible = true
	if is_instance_valid(beacon):
		beacon.visible = false

	tell_light.light_energy = 0.0
	set_aura_emitting(false)


func appear() -> void:
	visuals.visible = true
	health.invulnerable = false
	health.intangible = false
	if is_instance_valid(beacon):
		beacon.visible = true

	set_aura_emitting(true)


func set_speed(speed: float) -> void:
	move_mode.max_speed.x = speed


func set_light(color: Color, energy: float) -> void:
	if not is_instance_valid(tell_light):
		return

	if _light_tween != null:
		_light_tween.kill()
	tell_light.light_color = color
	tell_light.light_energy = energy


func set_aura_emitting(emitting: bool) -> void:
	if is_instance_valid(_aura):
		_aura.emitting = emitting


func fade_aura(duration: float) -> void:
	if is_instance_valid(_aura):
		_aura.fade_out(duration)


func _create_aura() -> void:
	EnemyVfx.impact(Spawner3D.root, global_position + Vector3.UP * SPAWN_BURST_HEIGHT, PHASE_COLORS[phase])
	_aura = EnemyVfx.aura(self, global_position + Vector3.UP * AURA_HEIGHT, PHASE_COLORS[phase], AURA_RADIUS)
	apply_phase_look()


func _on_died() -> void:
	brain.enter_state(&"Dead")
