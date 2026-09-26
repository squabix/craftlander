class_name ChestState
extends State


func enter() -> void:
	(root as TreasureChest).interactable.conditions.clear()


func interact(_player: Player) -> void:
	pass
