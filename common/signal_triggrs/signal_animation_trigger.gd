extends SignalTrigger
class_name SignalAnimationTrigger

@export var animation_player: AnimationPlayer
@export var animation_name: String
@export var force_from_start: bool = true

func trigger(..._args: Array) -> void:
	if not is_instance_valid(animation_player):
		return
	
	if force_from_start:
		animation_player.stop()
	
	animation_player.play(animation_name)
