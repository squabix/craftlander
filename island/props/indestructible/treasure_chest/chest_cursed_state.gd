class_name ChestCursedState
extends ChestState


func interact(_player: Player) -> void:
	(root as TreasureChest).play_locked()
