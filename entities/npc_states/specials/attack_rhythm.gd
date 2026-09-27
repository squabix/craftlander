class_name AttackRhythm
extends Node

@export var pattern: Array[StringName] = []
@export var enabled := true

var _index := 0


func current() -> StringName:
	return &"" if pattern.is_empty() else pattern[_index]


func is_special_due() -> bool:
	return enabled and current() != &""


func advance() -> void:
	if not pattern.is_empty():
		_index = (_index + 1) % pattern.size()


func count_basic_attack() -> void:
	if current() == &"":
		advance()


func take_ready_special(machine: StateMachine, sight: RadialSight3D) -> StringName:
	var special := get_ready_special(machine, sight)
	if special == null:
		return &""

	advance()
	return special.name


func get_ready_special(machine: StateMachine, sight: RadialSight3D) -> SpecialAttackState:
	if not is_special_due():
		return null

	var special := get_due_special(machine)
	if special == null or not special.can_start(special.enemy.distance_to_target()) or not sight.does_see_target():
		return null
	return special


func get_due_special(machine: StateMachine) -> SpecialAttackState:
	var special := machine.get_state(current()) as SpecialAttackState
	if special == null:
		Util.node_error("%s names %s, which is not a special attack state", self, current())
		advance()
	return special
