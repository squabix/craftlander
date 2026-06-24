extends Node
class_name InventorySelector

signal changed_selection
signal updated


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
			updated.emit()
			return
		
		selected_index = wrapi(to, 0, inventory.size)
		
		updated.emit()
		changed_selection.emit()

func _ready() -> void:
	if inventory == null:
		printerr(self, " has no inventory and will not work")
		return
	
	updated.emit.call_deferred()
	changed_selection.emit.call_deferred()
	
	inventory.changed.connect(updated.emit.call_deferred) # Hold current whenever inventory is changed

func is_index_valid(index: int) -> bool: return enabled and inventory.is_index_valid(index)

func get_current_instance() -> ItemInstance:
	if not is_index_valid(selected_index):
		return null
	return inventory.get_instance(selected_index)

func get_current_item() -> Item:
	if not is_index_valid(selected_index):
		return null
	return inventory.get_item(selected_index)
