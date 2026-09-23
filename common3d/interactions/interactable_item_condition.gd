class_name InteractableItemCondition
extends InteractableCondition

@export var items: Array[Item] = []
@export var remove_item_on_fulfilled := false


func is_met(_interactable: Interactable3D, source: Node) -> bool:
	var held := _get_held_item(source)
	return held != null and items.any(func(item: Item) -> bool: return item.equals(held))


func on_fulfilled(_interactable: Interactable3D, source: Node) -> void:
	if not remove_item_on_fulfilled:
		return
	var holder := Util.find_child_of_class(source, &"InventoryHolder3D") as InventoryHolder3D
	if is_instance_valid(holder):
		holder.consume_item()


func _get_held_item(source: Node) -> Item:
	var holder := Util.find_child_of_class(source, &"ItemHolder3D") as ItemHolder3D
	return holder.get_held_item() if is_instance_valid(holder) else null
