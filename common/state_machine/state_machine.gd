class_name StateMachine
extends State

signal entered_state(state: State)
signal exited_state(state: State)

@export var initial_state_name: StringName:
	get:
		if initial_state_name.is_empty():
			var children = get_children_states()
			if not children.is_empty():
				initial_state_name = children[0].name # Default to first child state name
		return initial_state_name

var current: StringName = &""
var states: Dictionary[StringName, State]


func _ready() -> void:
	if not get_parent() is StateMachine:
		process_update = true
		physics_process_update = true
		do_handle_input = true

	for state in get_children_states():
		state.enter_callable = enter_state
		state.root = root
		states[state.name] = state
	
	if is_valid():
		reload()
	else:
		enter_state(initial_state_name)


func get_children_states() -> Array[State]:
	var children_states: Array[State]
	children_states.assign(get_children().filter(Util.is_object_class.bind(&"State")))
	return children_states


func reload(force_ancestors := false) -> bool:
	var state := get_state(current)
	if not is_instance_valid(state):
		printerr("Cannot reload invalid current state: %s" % current)
		return false

	exit_current()

	if force_ancestors and get_parent() is StateMachine:
		get_parent().reload(true)

	state.is_active = true
	state.enter()
	state.entered.emit()
	entered_state.emit(state)

	return true


func _to_string() -> String:
	return name


func update_root(to: Node) -> void:
	if root == to:
		return
	root = to
	for state_name in states:
		var state := get_state(state_name)
		if not is_instance_valid(state):
			continue
		states[state_name].update_root(to)


func enter() -> void:
	enter_state(initial_state_name)


func exit() -> void:
	exit_current()


func is_valid() -> bool:
	return is_instance_valid(states.get(current))


func is_currently(state_name: StringName) -> bool:
	if not is_valid():
		return false
	return current == state_name


func update(delta: float) -> void:
	if is_currently(&"Chopped"):
		Util.iprint(0.5, current)
	if is_valid():
		states[current].update(delta)


func physics_update(delta: float) -> void:
	if is_valid():
		states[current].physics_update(delta)


func handle_input(event: InputEvent) -> void:
	if is_valid():
		states[current].handle_input(event)


func exit_current() -> void:
	if not is_valid():
		return
		
	var state := get_state(current)
	state.exit()
	state.exited.emit()
	exited_state.emit(state)
	state.is_active = false
	current = &""


func get_state(state_name: StringName) -> State:
	return states.get(state_name)


func enter_state(state_name: StringName, force_ancestors := false) -> bool:
	var state := states.get(state_name) as State
	if not is_instance_valid(state):
		printerr("Cannot enter invalid state: %s" % state_name)
		return false
	if state_name == current:
		return true

	if is_valid():
		var current_state := get_state(current)
		if current_state.priority > state.priority:
			return false
		exit_current()

	if force_ancestors and get_parent() is StateMachine:
		get_parent().enter_state(name, true)

	current = state_name

	state.is_active = true
	state.enter()
	state.entered.emit()
	entered_state.emit(state)

	return true
