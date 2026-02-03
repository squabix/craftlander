extends Node
class_name Inventory

signal changed

@export var item_instances: Array[ItemInstance] = []
@export var constant := false
@export var size := 5:
	set(to):
		size = to
		item_instances.resize(size)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	item_instances.resize(size)
	await get_tree().process_frame
	for instance in item_instances:
		if instance == null:
			continue
		if instance.quantity <= 0:
			item_instances.erase(instance)
		else:
			if instance is RandomItemInstance:
				item_instances[item_instances.find(instance)] = instance.duplicate()

func get_item(index: int) -> Item:
	var instance := item_instances[index]
	if instance == null:
		return null
	return instance.item

func add_item(new_item: Item, quantity: int = 1, must_reach_quantity: bool = false) -> int:
	if constant:
		return quantity
	if quantity == 0:
		return 0
	
	var original_quantity := quantity
	
	if new_item.max_quantity > 1:
		for inst in item_instances:
			if inst == null:
				continue
			if inst.item.equals(new_item) and inst.quantity < new_item.max_quantity:
				var space_left: int = new_item.max_quantity - inst.quantity
				var to_add: int = min(quantity, space_left)
				inst.quantity += to_add
				quantity -= to_add
				if quantity <= 0:
					changed.emit()
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
	
	if quantity > 0 and must_reach_quantity:
		remove_item(new_item, original_quantity - quantity)
		return original_quantity
	
	changed.emit()
	return quantity

func get_item_quantities() -> Dictionary[Item, int]:
	var quantities: Dictionary[Item, int] = {}
	for instance in item_instances:
		if instance == null:
			continue
		
		for item in quantities:
			if item.equals(instance.item):
				quantities[item] += instance.quantity
				continue
		
		quantities[instance.item] = instance.quantity
	
	return quantities

func get_first_empty_index() -> int:
	for index in size:
		if item_instances[index] == null:
			return index
	return -1

func get_valid_instances() -> Array[ItemInstance]:
	return item_instances.filter(func(a): return a != null)

func delete_instance(instance: ItemInstance) -> void:
	item_instances.erase(instance)
	changed.emit()

func get_random_index_weighted() -> int:
	var quantities := get_item_quantities()
	var total_weight := 0
	for weight in quantities.values():
		total_weight += weight
	
	if total_weight <= 0:
		return -1
	
	var r := randi() % total_weight
	var cumulative := 0
	
	var keys := quantities.keys()
	for i in len(keys):
		cumulative += quantities[keys[i]]
		if r < cumulative:
			return i
	
	return -1

func remove_item(item: Item, quantity: int = -1, must_reach_quantity: bool = false) -> int:
	if constant:
		return quantity
	if quantity == 0:
		return 0
	
	var item_quantity := get_item_quantities()[item]
	if quantity == -1:
		quantity = item_quantity
	elif must_reach_quantity and quantity > item_quantity:
		return quantity
	
	for i in range(item_instances.size() - 1, -1, -1):
		var inst := item_instances[i]
		if inst == null:
			continue
		
		if not inst.item.equals(item):
			continue
		
		quantity = remove_instance(inst, quantity)
		if quantity <= 0:
			changed.emit()
			return 0
		i -= 1
	changed.emit()
	return quantity

func give_item(item: Item, quantity: int, to: Inventory) -> int:
	var available_quantity := quantity if constant else quantity - remove_item(item, quantity)
	var leftover_quantity := to.add_item(item, available_quantity)
	return leftover_quantity

func clear() -> void:
	for i in len(item_instances):
		item_instances[i] = null

func give_everything(to: Inventory) -> void:
	for instance in get_valid_instances():
		give_item(instance.item, instance.quantity, to)

func is_empty() -> bool:
	return item_instances.filter(func(a): return a != null).is_empty()

func remove_instance(instance: ItemInstance, quantity: int=1) -> int:
	if constant:
		return 0
	
	if instance.quantity > quantity:
		instance.quantity -= quantity
		return 0
	else:
		quantity -= instance.quantity
		empty_instance.call_deferred(instance)
		if quantity <= 0:
			changed.emit()
			return 0
	changed.emit()
	return quantity

func empty_instance(instance: ItemInstance) -> void:
	item_instances[item_instances.find(instance)] = null

func is_index_valid(index: int) -> bool:
	return index < size and index >= 0 and item_instances[index] != null and item_instances[index].item != null

func get_instance(index: int) -> ItemInstance:
	if not is_index_valid(index):
		return null
	return item_instances[index]

func _to_string() -> String:
	return "Inventory of " + str(item_instances)
