class_name StateMachine
extends State

signal entered_state(state: State)
signal exited_state(state: State)

@export var initial_state: State:
	get:
		if not is_instance_valid(initial_state):
			for state in get_children_states():
				initial_state = state # Default to first child that is a state
				break
		return initial_state

var current: State
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
	
	if is_instance_valid(current):
		reload()
	else:
		enter_state(initial_state.name)


func get_children_states() -> Array[State]:
	var children_states: Array[State]
	children_states.assign(get_children().filter(Util.is_object_class.bind(&"State")))
	return children_states


func reload() -> void:
	enter_state(current.name)


func _to_string() -> String:
	return name


func update_root(to: Node) -> void:
	if root == to:
		return
	root = to
	for state_name in states:
		states[state_name].update_root(to)


func enter() -> void:
	enter_state(initial_state.name)


func exit() -> void:
	exit_current()


func is_valid() -> bool:
	return is_instance_valid(current)


func is_currently(state_name: StringName) -> bool:
	if not is_valid():
		return false
	return current.name == state_name


func update(delta: float) -> void:
	if is_valid():
		current.update(delta)


func physics_update(delta: float) -> void:
	if is_valid():
		current.physics_update(delta)


func handle_input(event: InputEvent) -> void:
	if is_valid():
		current.handle_input(event)


func exit_current() -> void:
	current.exit()
	current.exited.emit()
	exited_state.emit(current)
	current.is_active = false
	current = null


func get_state(state_name: StringName) -> State:
	return states[state_name]


func enter_state(state_name: StringName, force_ancestors := false) -> bool:
	if not state_name in states:
		return false

	var state := states[state_name]
	if not is_instance_valid(state):
		printerr("Cannot enter invalid state: %s" % state)
		return false
	if state == current:
		return true

	if is_valid():
		if current.priority > state.priority:
			return false
		exit_current()

	if force_ancestors and get_parent() is StateMachine:
		get_parent().enter_state(name, true)

	current = state

	current.is_active = true
	current.enter()
	current.entered.emit()
	entered_state.emit(current)

	return true
