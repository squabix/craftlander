class_name State
extends Node

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
@export var do_handle_input: bool

var transition_checks: Dictionary = { } # {check: state}
var enter_callable: Callable
var is_active := false


func _process(delta: float) -> void:
	if process_update:
		update(delta)


func _physics_process(delta: float) -> void:
	if physics_process_update:
		physics_update(delta)


func _input(event: InputEvent) -> void:
	if do_handle_input:
		handle_input(event)


func _to_string() -> String:
	return name


func enter() -> void:
	pass


func exit() -> void:
	pass


func update_root(to: Node) -> void:
	root = to


func add_check(target: State, callable: Callable) -> void:
	transition_checks[callable] = target


func transition_to(state_name: String) -> void:
	if not enter_callable.is_valid():
		printerr(self, "has invalid enter callable")
		return
	await get_tree().process_frame
	enter_callable.call(state_name)


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass
