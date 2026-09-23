class_name InteractableCondition
extends Resource

func is_met(_interactable: Interactable3D, _source: Node) -> bool:
	return true


func on_fulfilled(_interactable: Interactable3D, _source: Node) -> void:
	pass
