extends State
class_name StateMachine

signal entered_state(state: State)
signal exited_state(state: State)

@export var initial_state: State

var current: State

func _ready() -> void:
	if initial_state == null:
		initial_state = get_child(0)
		
	if not get_parent() is StateMachine:
		process_update = true
		physics_process_update = true
	
	enter_state(initial_state)
	for child in get_children():
		if child is State:
			child.enter_callable = enter_state

func enter() -> void:
	enter_state(initial_state)

func update(delta: float) -> void:
	if is_instance_valid(current):
		current.update(delta)
		current.check_transitions()

func physics_update(delta: float) -> void:
	if is_instance_valid(current):
		current.physics_update(delta)

func enter_state(state: State) -> bool:
	if not is_instance_valid(state):
		printerr("Cannot enter invalid state: " + str(state))
		return false
	
	if state == current:
		print("Already current")
		return false
	
	if is_instance_valid(current):
		if current.priority > state.priority:
			return false
		current.exit()
		current.exited.emit()
		exited_state.emit(current)
	
	current = state
	
	current.enter()
	current.entered.emit()
	entered_state.emit(current)
	
	return true

func _to_string() -> String:
	var string: String = "State Machine ({0})".format([get_children()])
	return string
