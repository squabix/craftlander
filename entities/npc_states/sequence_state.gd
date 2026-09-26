class_name SequenceState
extends State

var _health: Health


func enter() -> void:
	run()


func run() -> void:
	pass


func wait(seconds: float) -> bool:
	if not is_inside_tree():
		return false

	await get_tree().create_timer(seconds, false).timeout
	return is_alive()


func is_alive() -> bool:
	if not is_active or not is_inside_tree():
		return false

	if not is_instance_valid(_health):
		_health = Health.search(root)
	return not is_instance_valid(_health) or not _health.dead


func go_to(state_name: StringName) -> void:
	if is_alive():
		transition_to(state_name)
