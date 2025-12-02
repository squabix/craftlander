extends Node3D
class_name ItemVisualsContainer3D

@export var inventory_holder_link: InventoryHolderLink

func _ready() -> void:
	inventory_holder_link.updated_current.connect(update_visuals)

func reset_visuals() -> void:
	for child in get_children():
		child.queue_free()
		remove_child(child)

func update_visuals() -> void:
	reset_visuals()
	var instance: ItemInstance = inventory_holder_link.get_current_instance()
	if instance == null or instance.item == null or instance.item.visuals == null:
		return
	if instance.item.visuals.get_parent() != null:
		instance.item.visuals.get_parent().remove_child(instance.item.visuals)
	add_child(instance.item.visuals)
	instance.item.visuals.show()
