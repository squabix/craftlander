extends State
class_name StateMachine

signal entered_state(state: State)
signal exited_state(state: State)

@export var initial_state: State

var current: State

var states: Dictionary[String, State]

func default_initial_state() -> void:
	for child in get_children():
		if child is State:
			initial_state = child
			return

func _ready() -> void:
	if initial_state == null:
		default_initial_state()
		
	if not get_parent() is StateMachine:
		process_update = true
		physics_process_update = true
		do_handle_input = true
	
	for child in get_children():
		if child is State:
			child.enter_callable = enter_state
			child.root = root
			states[child.name] = child
	enter_state(initial_state.name)

func enter() -> void:
	enter_state(initial_state.name)

func exit() -> void:
	exit_current()

func is_valid() -> bool:
	return is_instance_valid(current)

func is_currently(state_name: String) -> bool:
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

func get_state(state_name: String) -> State:
	return states[state_name]

func enter_state(state_name: String) -> bool:
	var state := states[state_name]
	if not is_instance_valid(state):
		printerr("Cannot enter invalid state: " + str(state))
		return false
	if state == current:
		return false
	
	if is_valid():
		if current.priority > state.priority:
			return false
		exit_current()
	
	current = state
	
	current.is_active = true
	current.enter()
	current.entered.emit()
	entered_state.emit(current)
	
	return true

func _to_string() -> String:
	var string: String = name + " Machine ("
	for state_name in states:
		string += "  " + str(states[state_name])
	string += "  )"
	return string
