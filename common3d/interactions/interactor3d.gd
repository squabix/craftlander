extends Node
class_name Interactor3D

signal interacted_with(interactable: Interactable3D)

@export var root: Node
@export var id: int

func interact() -> Interactable3D:
	var parent: Node3D = get_parent() as Node3D
	if not is_instance_valid(parent):
		printerr("Cannot interact with invalid parent")
		return null
	
	var interactable: Interactable3D
	if parent is Area3D:
		interactable = get_closest_interactable(parent.get_overlapping_areas())
	elif parent is RayCast3D:
		interactable = parent.get_collider() as Interactable3D
	
	if not is_interactable_valid(interactable):
		return null
	
	interactable.interact(root)
	interacted_with.emit(interactable)
	return interactable

func is_interactable_valid(interactable: Interactable3D) -> bool:
	return is_instance_valid(interactable) and interactable.id == id

func get_closest_interactable(interacbles: Array) -> Interactable3D:
	var overlapping_interactables: Array[Interactable3D]
	
	for overlapping_area in interacbles:
		if not overlapping_area is Interactable3D:
			continue
		overlapping_interactables.append(overlapping_area)
	
	return Util.distance_sort_3d(overlapping_interactables, get_parent().global_position)[0]
