class_name Health
extends Node

signal survived_hurt
signal hp_changed
signal was_hurt
signal was_healed
signal died
signal revived
signal was_dealt_damage(amount)
signal was_given_hp(amount)

@export var hp := 5.0
@export var hurt_multiplier := 1.0
@export var immortal := false
@export var invulnerable := false
@export var one_shot := false
@export var free_parent_on_death := false

var dead := false

@onready var max_hp := hp


static func search(root: Node) -> Health:
	# BAIL if root doesn't exist
	if not is_instance_valid(root):
		return null

	for child in root.get_children():
		if child is Health:
			return child

	return null


func from_percent_max(percent: float) -> float:
	return percent * max_hp


func to_percent_max(a: float) -> float:
	return a / max_hp


func from_percent(percent: float) -> float:
	return percent * hp


func to_percent(a: float) -> float:
	return a / hp


func is_full() -> bool:
	return hp == max_hp


func heal(amount: float, can_revive: bool = false) -> void:
	if amount <= 0.0:
		return
	if hp <= 0.0 and not can_revive:
		return
	hp = min(max_hp, hp + abs(amount))
	was_healed.emit()
	was_given_hp.emit(amount)


func revive(revived_hp: float = max_hp) -> void:
	if revived_hp < 0.0:
		return
	if not dead:
		return
	dead = false
	heal(revived_hp, true)
	revived.emit()


func set_hp(to: float, can_hurt: bool = true, can_heal: bool = true) -> void:
	if to < hp:
		if can_hurt:
			hurt(hp - to)
	else:
		if can_heal:
			heal(to - hp)


func fill() -> void:
	var difference := max_hp - hp
	if difference > 0.0:
		heal(difference)


func empty() -> void:
	if hp > 0.0:
		hurt(hp)


func hurt(amount: float) -> void:
	if amount <= 0.0 or invulnerable:
		return

	amount *= hurt_multiplier
	was_dealt_damage.emit(amount)

	if dead:
		return

	hp = 0.0 if one_shot else max(0, hp - abs(amount))

	was_hurt.emit()
	hp_changed.emit()

	# Either die or survive
	if should_die():
		die()
	else:
		survive()


func should_die() -> bool:
	return not (hp > 0.0 or immortal)


func die() -> void:
	died.emit()
	dead = true
	if free_parent_on_death:
		Util.safe_free(get_parent())


func survive() -> void:
	survived_hurt.emit()
