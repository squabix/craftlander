extends Node
class_name InventorySelector

signal selected_new_index(index: int)
signal selected_instance_changed(instance: ItemInstance)

@export var enabled := true:
	set(to):
		enabled = to
		if not enabled and reset_selection_on_disable:
			selected_index = -1

@export var reset_selection_on_disable := false
@export var inventory: Inventory
@export var selected_index := 0:
	set(to):
		if not enabled:
			selected_index = -1
			return
		
		if selected_index == to:
			return
		
		if to == -1:
			selected_index = -1
		else:
			selected_index = wrapi(to, 0, inventory.size if inventory else 1)
		
		selected_new_index.emit(selected_index)
		update_current_instance()

var _last_instance: ItemInstance = null

func _ready() -> void:
	if inventory == null:
		printerr(self, " has no inventory and will not work")
		return
	
	selected_new_index.emit.call_deferred(selected_index)
	update_current_instance.call_deferred()
	
	inventory.item_changed.connect(
		func(index: int) -> void:
			if index != selected_index:
				return
			update_current_instance()
	)

func is_index_valid(index: int) -> bool: 
	return enabled and inventory.is_occupied(index)

func update_current_instance() -> void:
	var current := get_current_instance()
	if _last_instance != current:
		_last_instance = current
		selected_instance_changed.emit.call_deferred(current)

func get_current_instance() -> ItemInstance:
	if not is_index_valid(selected_index):
		return null
	return inventory.get_instance(selected_index)

func get_current_item() -> Item:
	if not is_index_valid(selected_index):
		return null
	return inventory.get_item(selected_index)
