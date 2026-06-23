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
	for i in item_instances.size():
		_initialize_slot(i)

func _initialize_slot(index: int) -> void:
	var instance = item_instances[index]
	if instance == null:
		return
	
	if instance.quantity <= 0:
		item_instances[index] = null
	elif instance is RandomItemInstance:
		item_instances[index] = instance.duplicate()

func get_item(index: int) -> Item:
	return item_instances[index].item if is_index_valid(index) else null

func get_instance(index: int) -> ItemInstance:
	return item_instances[index] if is_index_valid(index) else null

func is_index_valid(index: int) -> bool:
	return index >= 0 and index < size and item_instances[index] != null and item_instances[index].item != null

func get_first_empty_index() -> int:
	return item_instances.find(null)

func is_empty() -> bool: return item_instances.all(func(slot): return slot == null)

func get_valid_instances() -> Array[ItemInstance]: return item_instances.filter(func(slot): return slot != null)

func get_item_quantities() -> Dictionary:
	var quantities: Dictionary = {}
	for inst in get_valid_instances():
		if quantities.has(inst.item):
			quantities[inst.item] += inst.quantity
		else:
			quantities[inst.item] = inst.quantity
	return quantities

func get_item_quantity(item: Item) -> int:
	if item == null: 
		return 0
	
	var quantities := get_item_quantities()
	return quantities.get(item, 0)

func add_item(new_item: Item, quantity: int = 1, must_reach_quantity: bool = false) -> int:
	if constant:
		return quantity
	if quantity <= 0:
		return 0
	
	var original_quantity := quantity
	
	if new_item.max_quantity > 1:
		quantity = fill_existing_stacks(new_item, quantity)
		
	if quantity > 0:
		quantity = create_new_stacks(new_item, quantity)
	
	if quantity > 0 and must_reach_quantity:
		remove_item(new_item, original_quantity - quantity)
		return original_quantity
		
	if quantity != original_quantity:
		changed.emit()
	return quantity

func fill_existing_stacks(new_item: Item, quantity: int) -> int:
	for inst in get_valid_instances():
		if not _is_stackable_with(inst, new_item): continue
		
		var space_left := new_item.max_quantity - inst.quantity
		var to_add: int = min(quantity, space_left)
		inst.quantity += to_add
		quantity -= to_add
		if quantity <= 0: break
	return quantity

func create_new_stacks(new_item: Item, quantity: int) -> int:
	while quantity > 0:
		var empty_idx := get_first_empty_index()
		if empty_idx == -1: break
		
		var to_add: int = min(quantity, new_item.max_quantity)
		var instance := new_item.get_instance(to_add)
		instance.emptied.connect(empty_instance.bind(instance))
		
		item_instances[empty_idx] = instance
		quantity -= to_add
	return quantity

func _is_stackable_with(instance: ItemInstance, item: Item) -> bool:
	return instance != null and item != null and instance.item.equals(item) and instance.quantity < item.max_quantity

func remove_item(item: Item, quantity: int, must_reach_quantity: bool = false) -> int:
	if constant:
		return quantity
	if quantity == 0:
		return 0
	
	var total_available := get_item_quantity(item)
	if must_reach_quantity and quantity > total_available: return quantity
	
	var start_quantity := quantity
	for i in range(item_instances.size() - 1, -1, -1):
		var inst = item_instances[i]
		if inst == null or not inst.item.equals(item): continue
		
		quantity = remove_instance(inst, quantity)
		if quantity <= 0: break
		
	if quantity != start_quantity:
		changed.emit()
	return quantity

func remove_instance(instance: ItemInstance, quantity: int) -> int:
	if constant: return 0
	if instance == null: return quantity
	
	if instance.quantity > quantity:
		instance.quantity -= quantity
		changed.emit()
		return 0
	else:
		quantity -= instance.quantity
		empty_instance(instance)
		return quantity

func empty_instance(instance: ItemInstance) -> void:
	var idx := item_instances.find(instance)
	if idx == -1:
		return
	item_instances[idx] = null
	changed.emit()

func give_item(item: Item, quantity: int, to: Inventory) -> int:
	var available := quantity if constant else quantity - remove_item(item, quantity)
	return to.add_item(item, available)

func clear() -> void:
	item_instances.fill(null)
	changed.emit()

func give_everything(to: Inventory) -> void:
	for inst in get_valid_instances():
		give_item(inst.item, inst.quantity, to)

func get_random_index_weighted() -> int:
	var quantities := get_item_quantities()
	var total_weight := 0
	for weight in quantities.values(): total_weight += weight
	if total_weight <= 0: return -1
	
	var r := randi() % total_weight
	var cumulative := 0
	var keys := quantities.keys()
	
	for i in len(keys):
		cumulative += quantities[keys[i]]
		if r < cumulative: return i
	return -1

func _to_string() -> String:
	return "Inventory of " + str(item_instances)
