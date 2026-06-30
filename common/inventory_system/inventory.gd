class_name Inventory
extends Node

signal instance_changed(index: int)
signal item_changed(index: int)

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
	item_changed.connect(instance_changed.emit)


func _to_string() -> String:
	return "Inventory of %s" % str(get_occupied_indexes())


func get_item(index: int) -> Item:
	return item_instances[index].item if is_occupied(index) else null


func get_instance(index: int) -> ItemInstance:
	return item_instances[index] if is_occupied(index) else null


func has_index(index: int) -> bool:
	return index >= 0 and index < size


func is_occupied(index: int) -> bool:
	return index >= 0 and index < size and item_instances[index] != null and item_instances[index].item != null


func get_first_empty_index() -> int:
	return item_instances.find(null)


func get_instance_index(item_instance: ItemInstance) -> int:
	return item_instances.find(item_instance)


func get_item_index(item: Item) -> int:
	for index in len(item_instances):
		if not is_occupied(index):
			continue
		var instance := item_instances[index]
		if not instance.item.equals(item):
			continue
		return index
	return -1


func is_empty() -> bool:
	return item_instances.all(func(instance: ItemInstance) -> bool: return instance == null)


func get_occupied_indexes() -> Array:
	return get_all_indexes().filter(
		func(index: int) -> bool:
			return is_occupied(index)
	)


func get_all_indexes() -> Array:
	return range(len(item_instances))


func get_item_quantities() -> Dictionary[Item, int]:
	var quantities: Dictionary[Item, int] = { }
	for index in get_occupied_indexes():
		var instance := get_instance(index)
		if quantities.has(instance.item):
			quantities[instance.item] += instance.quantity
		else:
			quantities[instance.item] = instance.quantity
	return quantities


func get_item_quantity(item: Item) -> int:
	if item == null:
		return 0

	var quantities := get_item_quantities()
	return quantities.get(item, 0)


func has_room(item: Item, quantity: int) -> bool:
	if constant:
		return false

	if item == null or quantity <= 0:
		return true

	# Check space inside existing stackable matching item slots
	var remaining_quantity := quantity - get_stackable_room(item)
	if remaining_quantity <= 0:
		return true

	# Check if the remaining empty slots can handle what's left over
	var total_empty_slot_capacity := count_empty_slots() * item.max_quantity
	return remaining_quantity <= total_empty_slot_capacity


func count_empty_slots() -> int:
	var count := 0
	for instance in item_instances:
		if instance == null:
			count += 1
	return count


func get_stackable_room(item: Item) -> int:
	if item.max_quantity <= 1:
		return 0

	var room := 0

	for index in get_occupied_indexes():
		var instance := get_instance(index)
		if not instance.is_stackable_with(item):
			continue
		room += item.max_quantity - instance.quantity

	return room


func add_item(new_item: Item, quantity: int = 1, must_reach_quantity: bool = false) -> int:
	if constant:
		return quantity

	if new_item == null:
		return quantity

	if quantity <= 0:
		printerr("%s cannot add %s with quantity of %s" % [self, new_item, quantity])
		return 0

	var original_quantity := quantity

	if new_item.max_quantity > 1:
		quantity = fill_existing_stacks(new_item, quantity)

	if quantity > 0:
		quantity = create_new_stacks(new_item, quantity)

	# If didn't reach goal quantity, reverse all the work done
	if quantity > 0 and must_reach_quantity:
		remove_item(new_item, original_quantity - quantity)
		return original_quantity

	return quantity


func fill_existing_stacks(new_item: Item, quantity: int) -> int:
	if quantity <= 0:
		printerr("%s cannot fill existing stacks of %s with quantity of %s" % [self, new_item, quantity])
		return 0

	if new_item == null:
		return quantity

	var indexes := get_occupied_indexes()
	for index in indexes:
		var instance := get_instance(index)

		if not instance.is_stackable_with(new_item):
			continue

		var space_left := new_item.max_quantity - instance.quantity
		var to_add: int = min(quantity, space_left)

		instance.quantity += to_add
		quantity -= to_add
		instance_changed.emit(index)
		if quantity <= 0:
			break

	return quantity


func create_instance(index: int, item: Item, quantity: int, overwrite_occupied := true) -> ItemInstance:
	if item == null:
		printerr("%s cannot create instance at %s with null item" % [self, index])
		return null
	if quantity == 0:
		printerr("%s cannot create instance at %s with quantity of zero" % [self, index])
		return null

	if index == -1:
		return null
	if not overwrite_occupied and is_occupied(index):
		return null

	var instance := item.instantiate(quantity)
	instance.emptied.connect(func() -> void: empty_instance(get_instance_index(instance)))
	item_instances[index] = instance
	item_changed.emit(index)
	return instance


func create_new_stacks(new_item: Item, quantity: int) -> int:
	while quantity > 0:
		var empty_index := get_first_empty_index()
		if empty_index == -1:
			break

		var to_add: int = min(quantity, new_item.max_quantity)
		create_instance(empty_index, new_item, to_add)
		quantity -= to_add
	return quantity


func remove_item(item: Item, quantity: int, must_reach_quantity: bool = false) -> int:
	if constant:
		return quantity
	if quantity == 0:
		return 0

	var total_available := get_item_quantity(item)
	if must_reach_quantity and quantity > total_available:
		return quantity

	for index in range(item_instances.size() - 1, -1, -1):
		if not is_occupied(index):
			continue

		var instance := item_instances[index]
		if not instance.item.equals(item):
			continue

		quantity = remove_instance(index, quantity)

		if quantity <= 0:
			break

	return quantity


func remove_instance(index: int, quantity: int) -> int:
	if constant:
		return 0
	if not is_occupied(index):
		return quantity

	var instance := get_instance(index)

	if instance.quantity > quantity:
		instance.quantity -= quantity
		instance_changed.emit(index)
		return 0
	else:
		quantity -= instance.quantity
		empty_instance(index)
		return quantity


func empty_instance(index: int) -> void:
	if not has_index(index):
		return

	item_instances[index] = null
	item_changed.emit(index)


func give_item(item: Item, quantity: int, to: Inventory) -> int:
	var available := quantity if constant else quantity - remove_item(item, quantity)
	return to.add_item(item, available)


func clear() -> void:
	item_instances.fill(null)
	for i in size:
		item_changed.emit(i)


func swap(index1: int, index2: int) -> bool:
	if index1 < 0 or index1 >= size or index2 < 0 or index2 >= size:
		return false

	if index1 == index2:
		return false

	var temp := item_instances[index1]
	item_instances[index1] = item_instances[index2]
	item_instances[index2] = temp

	item_changed.emit(index1)
	item_changed.emit(index2)
	return true

	#instance_changed.emit(index1)
	#instance_changed.emit(index2)


func give_everything(to: Inventory) -> void:
	for index in get_occupied_indexes():
		var instance := get_instance(index)
		give_item(instance.item, instance.quantity, to)


func get_random_index_weighted() -> int:
	var occupied := get_occupied_indexes()
	var total_weight := 0

	for index in occupied:
		total_weight += get_instance(index).quantity

	if total_weight <= 0:
		return -1

	var r := randi() % total_weight
	var cumulative := 0

	for index in occupied:
		cumulative += get_instance(index).quantity
		if r < cumulative:
			return index
	return -1


func _initialize_slot(index: int) -> void:
	var instance = item_instances[index]
	if instance == null:
		return

	if instance.quantity <= 0:
		item_instances[index] = null
	elif instance is RandomItemInstance:
		item_instances[index] = instance.duplicate()
