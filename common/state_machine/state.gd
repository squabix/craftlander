extends Node
class_name State

signal was_locked
signal was_unlocked

@warning_ignore("unused_signal")
signal entered
@warning_ignore("unused_signal")
signal exited

@export var root: Node
@export var priority: float
@export var locked: bool:
	set(to):
		locked = true
		if to == true:
			was_locked.emit()
		else:
			was_unlocked.emit()
@export var process_update: bool
@export var physics_process_update: bool

var transition_checks: Dictionary = {} # {check: state}
var enter_callable: Callable


func enter() -> void:
	pass

func exit() -> void:
	pass

func add_check(target: State, callable: Callable) -> void:
	transition_checks[callable] = target

func transition_to(state_name: String) -> void:
	if not enter_callable.is_valid():
		printerr(self, "has invalid enter callable")
		return
	await get_tree().process_frame
	enter_callable.call(state_name)

func _process(delta: float) -> void:
	if process_update:
		update(delta)

func _physics_process(delta: float) -> void:
	if physics_process_update:
		physics_update(delta)

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func check_transitions() -> void:
	pass
	#for check in transition_checks:
		#if check.call() == true:
			#transition_to(transition_checks[check])
			#return
