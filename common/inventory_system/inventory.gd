extends Node
class_name Inventory

@export var item_instances: Array[ItemInstance] = []
@export var size := 5:
	set(to):
		size = to
		item_instances.resize(size)

func _ready() -> void:
	item_instances.resize(size)
	await get_tree().process_frame
	for instance in item_instances:
		if instance == null:
			continue
		if instance.quantity <= 0:
			item_instances.erase(instance)
		else:
			item_instances[item_instances.find(instance)] = instance.duplicate()

func add_item(new_item: Item, quantity: int = 1) -> int:
	if new_item.max_quantity > 1:
		for inst in item_instances:
			if inst == null:
				continue
			if inst.item == new_item and inst.quantity < new_item.max_stack:
				var space_left: int = new_item.max_stack - inst.quantity
				var to_add: int = min(quantity, space_left)
				inst.quantity += to_add
				quantity -= to_add
				if quantity <= 0:
					return 0
	# Add new stacks or unstackable items
	while quantity > 0:
		var index: int = get_first_empty_index()
		if index == -1:
			break
		
		var to_add: int = min(quantity, new_item.max_quantity)
		var instance := new_item.get_instance(quantity)
		instance.emptied.connect(delete_instance.bind(instance))
		item_instances[index] = instance
		quantity -= to_add
	
	return quantity

func get_first_empty_index() -> int:
	for index in size:
		if item_instances[index] == null:
			return index
	return -1

func delete_instance(instance: ItemInstance) -> void:
	item_instances.erase(instance)

func remove_item(item: Item, quantity: int=1) -> int:
	for i in range(item_instances.size()):
		var inst := item_instances[i]
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
		item_instances[item_instances.find(instance)] = null
		if quantity <= 0:
			return 0
	return quantity

func is_index_valid(index: int) -> bool:
	return index < size and index >= 0 and item_instances[index] != null

func get_instance(index: int) -> ItemInstance:
	if not is_index_valid(index):
		return null
	return item_instances[index]
