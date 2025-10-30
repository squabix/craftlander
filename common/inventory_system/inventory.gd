extends Node
class_name Inventory

@export var items: Array[ItemInstance] = []
@export var size: int = 5:
	set(to):
		size = to
		items.resize(size)

func _ready() -> void:
	items.resize(size)

func add_item(new_item: Item, quantity: int = 1) -> void:
	if new_item.is_stackable:
		for inst in items:
			if inst.item == new_item and inst.quantity < new_item.max_stack:
				var space_left = new_item.max_stack - inst.quantity
				var to_add = min(quantity, space_left)
				inst.quantity += to_add
				quantity -= to_add
				if quantity <= 0:
					return
	# Add new stacks or unstackable items
	while quantity > 0:
		var to_add = min(quantity, new_item.max_quantity)
		var instance = new_item.get_instance(quantity)
		instance.emptied.connect(delete_instance.bind(instance))
		items.append(instance)
		quantity -= to_add

func delete_instance(instance: ItemInstance) -> void:
	items.erase(instance)

func remove_item(item: Item, quantity: int=1) -> int:
	for i in range(items.size()):
		var inst = items[i]
		if inst == null or inst.item != item:
			continue
		remove_instance(inst, quantity)
		i -= 1
		if quantity <= 0:
			return 0
	return quantity

func remove_instance(instance: ItemInstance, quantity: int=1) -> int:
	if instance.quantity > quantity:
		instance.quantity -= quantity
		return 0
	else:
		quantity -= instance.quantity
		items[items.find(instance)] = null
		if quantity <= 0:
			return 0
	return quantity

func is_index_valid(index: int) -> bool:
	return index < size and index >= 0 and items[index] != null

func get_instance(index: int) -> ItemInstance:
	if not is_index_valid(index):
		return null
	return items[index]
