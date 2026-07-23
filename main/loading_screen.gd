class_name LoadingScreen
extends Control

signal transitioned_in
signal transitioned_out
signal requested_load(path: String)
signal loaded_resource(resource: Resource)
signal completed(resource: Resource)

enum FreeMode {
	NEVER,
	COMPLETE,
	TRANSITION_OUT,
}

@export var free_mode := FreeMode.NEVER

@export_group("Progress Bar", "progress")
@export var progress_bar: ProgressBar
@export var progress_complete_distance_ratio := 0.01
@export_range(0.0, 1.0) var progress_steps_ratio := 0.0

@export_group("Transitions", "transition")
@export var transition_player: AnimationPlayer
@export var transition_in_anim := &""

@export var transition_out_anim := &""
@export_subgroup("Transition In Settings", "transition_in")
@export var transition_in_before_load := false
@export_subgroup("Transition Out Settings", "transition_out")

@export_group("Steps")
@export var resource_load_step := "Loading"
@export var post_load_steps: Array[String] = []

@export_subgroup("Label", "step")
@export var step_label: Label
@export var step_label_format := "%s..."

var resource_path := ""
var active := false
var is_resource_loaded := false
var has_requested_load := false
var resource: Resource
var current_step_index := 0:
	set(new_val):
		current_step_index = clampi(new_val, 0, post_load_steps.size() + 1)
		update_progress_bar()
		_check_completion()
var resource_progress: Array[float] = [0.0]
var _frames := 0


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if is_instance_valid(transition_player):
		transition_player.animation_finished.connect(_on_transition_finished)


func _process(_delta: float) -> void:
	_frames += 1
	if not active:
		return

	if is_instance_valid(step_label):
		step_label.text = step_label_format % get_step(current_step_index)

	# Handle threaded resource loading if not yet finished
	if not is_resource_loaded:
		update_progress_bar()

		match ResourceLoader.load_threaded_get_status(resource_path, resource_progress):
			ResourceLoader.THREAD_LOAD_LOADED:
				is_resource_loaded = true
				resource = ResourceLoader.load_threaded_get(resource_path)
				loaded_resource.emit(resource)

				# If there are no post-loading steps, automatically advance to complete
				if post_load_steps.is_empty():
					advance_step()
					return
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("%s failed to load resource at %s" % [self, resource_path])
				active = false
				return

	_check_completion()


func reset_steps() -> void:
	post_load_steps.clear()


func add_steps(...steps: Array) -> void:
	post_load_steps.append_array(steps)


func request_load(path: String) -> bool:
	if has_requested_load:
		return false

	if path.is_empty():
		printerr("%s cannot request load for empty path" % self)
		return false

	if not ResourceLoader.exists(path):
		printerr("%s cannot request load for nonexistant path (%s)" % [self, path])
		return false

	ResourceLoader.load_threaded_request(path)
	has_requested_load = true
	requested_load.emit(path)
	return true


func load_resource(path: String) -> Resource:
	if path.is_empty():
		printerr("%s cannot load empty path" % self)
		return null

	if not ResourceLoader.exists(path):
		printerr("%s cannot load nonexistant path (%s)" % [self, path])
		return null
	
	if transition_in_before_load:
		await transition_in()
	else:
		transition_in()

	active = true
	reset()
	resource_path = path

	if not request_load(path):
		printerr("%s failed to load resource at %s" % [self, path])

	return await loaded_resource


func reset() -> void:
	is_resource_loaded = false
	has_requested_load = false
	current_step_index = 0
	resource_progress = [0.0]
	if progress_bar:
		progress_bar.value = 0.0
		if progress_bar is InterpolatedBar:
			progress_bar.target_value = 0.0


func advance_step() -> String:
	if not is_resource_loaded:
		printerr("%s cannot advance step before resource is loaded")
		return resource_load_step
	current_step_index += 1
	return get_step(current_step_index)


func get_step(index: int) -> String:
	if index == 0 or post_load_steps.is_empty():
		return resource_load_step
	return (
			post_load_steps[index - 1] if index <= post_load_steps.size()
			else post_load_steps[-1]
	)


func update_progress_bar() -> void:
	if not is_instance_valid(progress_bar):
		return

	var load_raw_progress := resource_progress[0] if not resource_progress.is_empty() else 0.0
	var load_ratio := load_raw_progress * (1.0 - progress_steps_ratio)

	var step_ratio := 0.0
	if not post_load_steps.is_empty():
		var completed_steps := minf(float(current_step_index), float(post_load_steps.size()))
		step_ratio = (completed_steps / float(post_load_steps.size())) * progress_steps_ratio
	elif current_step_index > 0:
		step_ratio = progress_steps_ratio

	var total_ratio := clampf(load_ratio + step_ratio, 0.0, 1.0)
	var final_value := progress_bar.max_value * total_ratio

	if progress_bar is InterpolatedBar:
		progress_bar.target_value = final_value
	else:
		progress_bar.value = final_value


func transition_in() -> void:
	if not is_instance_valid(transition_player):
		return
	if not transition_player.has_animation(transition_in_anim):
		printerr("%s cannot play nonexistant transition in animation '%s'" % [transition_player, transition_in_anim])
		return
	transition_player.play(transition_in_anim)
	
	await transition_player.animation_finished


func transition_out(force_free := false) -> void:
	if not is_instance_valid(transition_player):
		return
	if not transition_player.has_animation(transition_out_anim):
		printerr("%s cannot play nonexistant transition out animation '%s'" % [transition_player, transition_out_anim])
		return
	transition_player.play(transition_out_anim)
	if force_free:
		await transition_player.animation_finished
		queue_free()


func complete() -> void:
	active = false
	resource = ResourceLoader.load_threaded_get(resource_path)
	completed.emit(resource)
	if free_mode == FreeMode.COMPLETE:
		queue_free()
		return

	transition_out()


func _on_transition_finished(transition: StringName) -> void:
	match transition:
		transition_in_anim:
			transitioned_in.emit()
		transition_out_anim:
			transitioned_out.emit()


func _check_completion() -> void:
	if not active or not is_resource_loaded or current_step_index == 0:
		return

	if is_instance_valid(progress_bar):
		if progress_complete_distance_ratio > 0.0 and progress_bar.value > progress_bar.max_value * (1.0 - progress_complete_distance_ratio):
			complete()
	elif current_step_index == post_load_steps.size() + 1:
		complete()
