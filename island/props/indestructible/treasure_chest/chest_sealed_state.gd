class_name ChestSealedState
extends ChestState


func interact(_player: Player) -> void:
	var chest := root as TreasureChest
	chest.play_locked()
	EventBus.trigger(&"treasure_chest_touched", chest)
	transition_to(&"Cursed")
