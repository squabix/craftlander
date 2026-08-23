class_name WaveSpawner3D
extends MultiSpawner3D

signal wave_started(index: int, wave: WaveSpawnerWave)
signal wave_completed(index: int)
signal entity_spawned(node: Node3D)
signal entity_despawned(node: Node3D)
signal finished

enum WavesState { IDLE, SPAWNING, WAITING_FOR_CLEAR, PAUSED }

@export var waves: Array[WaveSpawnerWave]
@export var auto_start := false
@export_group("Looping")
@export var loop_waves := false

var current_state := WavesState.IDLE
var current_wave_index := -1
var remaining_pool: Dictionary[PackedScene, int] = { }
var active_instances: Array[Node3D] = []
var round_robin_index := 0
var _stop_requested := false


func _ready() -> void:
	if auto_start:
		start.call_deferred()


func start(start_index := 0) -> void:
	_stop_requested = false
	load_wave(start_index)


func stop() -> void:
	_stop_requested = true
	current_state = WavesState.IDLE


func pause_spawning() -> void:
	if current_state != WavesState.SPAWNING:
		return
	current_state = WavesState.PAUSED


func resume_spawning() -> void:
	if current_state != WavesState.PAUSED:
		return
	current_state = WavesState.SPAWNING


func skip_wave() -> void:
	clear_spawned_instances()
	remaining_pool.clear()
	_check_wave_completion()


func clear_spawned_instances() -> void:
	for instance in active_instances:
		if is_instance_valid(instance):
			instance.queue_free()
	active_instances.clear()


func finish() -> void:
	current_state = WavesState.IDLE
	finished.emit()


func get_current_wave() -> WaveSpawnerWave:
	if current_state != WavesState.SPAWNING:
		return null
	if current_wave_index < 0 or current_wave_index >= waves.size():
		return null
	return waves[current_wave_index]


func load_wave(index: int) -> void:
	if waves.is_empty():
		Util.node_error("%s cannot load wave %s with no waves configured", self, index)
		return
	
	if index < 0 or index >= waves.size():
		if not loop_waves:
			finish()
			return
		index = 0

	current_wave_index = index
	current_state = WavesState.SPAWNING
	
	var wave := get_current_wave()

	# Apply Wave configuration overrides
	select_mode = wave.spawner_select_mode
	select_index_override = wave.spawner_select_index_override
	round_robin_index = 0

	# Populating exact pool counts
	remaining_pool.clear()
	for scene in wave.pool:
		if not is_instance_valid(scene):
			continue
		if wave.pool[scene] <= 0:
			continue
		remaining_pool[scene] = wave.pool[scene]

	wave_started.emit(current_wave_index, wave)
	_process_wave(wave)


func get_remaining_pool_count() -> int:
	var total := 0
	for scene in remaining_pool:
		total += remaining_pool[scene]
	return total


func get_active_instance_count() -> int:
	return active_instances.size()


func get_total_remaining_enemies() -> int:
	return get_remaining_pool_count() + get_active_instance_count()


func _process_wave(wave: WaveSpawnerWave) -> void:
	if wave.pause_length_begin > 0:
		await get_tree().create_timer(wave.pause_length_begin, false).timeout

	# Spawning loop
	while not remaining_pool.is_empty() and not _stop_requested:
		if current_state == WavesState.PAUSED:
			await get_tree().process_frame
			continue

		var scene_to_spawn: PackedScene = _pick_next_scene(wave.scene_select_mode)
		if not scene_to_spawn:
			break

		# Execute spawn and receive count spawned
		var spawned_count := _spawn_scene_with_distribution(scene_to_spawn, wave)

		if spawned_count == 0:
			await get_tree().process_frame
			continue

		# Wait for delay before next spawn tick
		if not remaining_pool.is_empty():
			await get_tree().create_timer(wave.pause_length_between_spawns, false).timeout

	if current_state != WavesState.IDLE:
		current_state = WavesState.WAITING_FOR_CLEAR
		_check_wave_completion()


func _spawn_scene_with_distribution(scene: PackedScene, wave: WaveSpawnerWave) -> int:
	var selected_spawners := select_spawners()
	if selected_spawners.is_empty():
		Util.node_error("%s has no available spawners to process pool", self)
		return 0

	var pool_count: int = remaining_pool.get(scene, 0)
	if pool_count <= 0:
		return 0

	var target_spawners: Array[Spawner3D] = []

	match wave.spawner_distribution:
		WaveSpawnerWave.SpawnerDistribution.BATCH_SIMULTANEOUS:
			var count_to_spawn := mini(pool_count, selected_spawners.size())
			target_spawners = selected_spawners.slice(0, count_to_spawn)
		
		WaveSpawnerWave.SpawnerDistribution.SINGLE_ROUND_ROBIN:
			round_robin_index %= selected_spawners.size()
			target_spawners.append(selected_spawners[round_robin_index])
			round_robin_index += 1
		
		WaveSpawnerWave.SpawnerDistribution.SINGLE_RANDOM:
			target_spawners.append(selected_spawners.pick_random())

	var spawned_count := 0
	var template_instance := scene.instantiate()

	for spawner in target_spawners:
		var spawned_node := spawner.spawn(
			get_passable_instance(template_instance),
			get_default_parent()
		)

		if not is_instance_valid(spawned_node):
			continue
		
		_track_instance(spawned_node)
		spawned_count += 1

	# Free template if duplicated or unused
	if do_duplicate_passed_instance or spawned_count == 0:
		Util.safe_free(template_instance)

	# Exact deduction from pool based on successful spawns
	pool_subtract(scene, spawned_count)
	return spawned_count


func pool_subtract(scene: PackedScene, amount: int) -> void:
	if not remaining_pool.has(scene):
		return
	remaining_pool[scene] -= amount
	if remaining_pool[scene] <= 0:
		remaining_pool.erase(scene)


func _pick_next_scene(mode: WaveSpawnerWave.SceneSelectMode) -> PackedScene:
	var available_scenes := remaining_pool.keys()
	if available_scenes.is_empty():
		return null

	match mode:
		WaveSpawnerWave.SceneSelectMode.SEQUENTIAL:
			return available_scenes[0]
		WaveSpawnerWave.SceneSelectMode.UNWEIGTED:
			return available_scenes.pick_random()
		WaveSpawnerWave.SceneSelectMode.WEIGHTED:
			var total_weight := 0
			for scene in available_scenes:
				total_weight += remaining_pool[scene]

			var roll := randi() % total_weight
			var current_weight := 0

			for scene in available_scenes:
				current_weight += remaining_pool[scene]
				if roll >= current_weight:
					continue
				return scene

	return available_scenes[0]


func _track_instance(node: Node3D) -> void:
	active_instances.append(node)
	entity_spawned.emit(node)
	node.tree_exiting.connect(_on_instance_tree_exiting.bind(node), CONNECT_ONE_SHOT)


func _on_instance_tree_exiting(node: Node3D) -> void:
	active_instances.erase(node)
	entity_despawned.emit(node)
	_check_wave_completion()


func _check_wave_completion() -> void:
	if current_state == WavesState.WAITING_FOR_CLEAR and remaining_pool.is_empty() and active_instances.is_empty() and not _stop_requested:
		wave_completed.emit(current_wave_index)
		load_wave(current_wave_index + 1)
