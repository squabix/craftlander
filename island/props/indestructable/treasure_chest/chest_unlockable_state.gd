class_name ChestUnlockableState
extends ChestState

var key_required := true


func enter() -> void:
	var chest := root as TreasureChest
	var conditions: Array[InteractableCondition] = []
	if key_required:
		conditions.append(chest.key_condition)
	chest.interactable.conditions.assign(conditions)


func interact(_player: Player) -> void:
	var chest := root as TreasureChest
	chest.open()
	transition_to(&"Opened")
