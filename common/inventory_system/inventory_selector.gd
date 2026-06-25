extends Node
class_name InventorySelector

signal selected_new_index(index: int)

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
		
		selected_index = wrapi(to, 0, inventory.size)
		
		selected_new_index.emit(selected_index)

var _last_instance: ItemInstance = null

func _ready() -> void:
	if inventory == null:
		printerr(self, " has no inventory and will not work")
		return
	
	selected_new_index.emit.call_deferred(selected_index)
	
	# Check instance update
	inventory.item_changed.connect(
		func(index: int) -> void:
			if index != selected_index:
				return
			check_instance_update()
	)

func is_index_valid(index: int) -> bool: return enabled and inventory.is_occupied(index)

func check_instance_update() -> void:
	var current := get_current_instance()
	if _last_instance != current:
		_last_instance = current

func get_current_instance() -> ItemInstance:
	if not is_index_valid(selected_index):
		return null
	return inventory.get_instance(selected_index)

func get_current_item() -> Item:
	if not is_index_valid(selected_index):
		return null
	return inventory.get_item(selected_index)
