class_name SignalAnimationTrigger
extends SignalTrigger

@export var anim_player: AnimationPlayer
@export var anim_name: String
@export var force_from_start: bool = true


func trigger(..._args: Array) -> void:
	if not is_instance_valid(anim_player):
		return

	if force_from_start:
		anim_player.stop()

	anim_player.play(anim_name)
