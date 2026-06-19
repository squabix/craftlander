extends Node
class_name InventoryHolder

signal updated_current
signal changed

const NUM_KEY_INDEX_MAP: Dictionary[int, int] = {
	KEY_1: 0,
	KEY_2: 1,
	KEY_3: 2,
	KEY_4: 3,
	KEY_5: 4,
	KEY_6: 5,
	KEY_7: 6,
	KEY_8: 7,
	KEY_9: 8,
	KEY_0: 9,
}

@export var enabled := true
@export var inventory: Inventory
@export var item_holder: ItemHolder3D

@export_group("Indexing")
@export var current_index := 0:
	set(to):
		if current_index == to:
			hold_current()
			return
		
		# Wrap current index between min index and max index (or inventory size if no max index is set)
		current_index = wrapi(to, min_index, inventory.size if max_index == -1 else max_index)
		
		hold_current()
		updated_current.emit()
@export var min_index := 0
@export var max_index := -1

@export_group("Input")
@export var use_num_key_input := false
@export var scroll_up_input_action := ""
@export var scroll_down_input_action := ""

func _ready() -> void:
	if inventory == null:
		printerr(name, " has no inventory and will not function")
		return
	
	# Immediately hold current item, then emit that current has been updated
	hold_current.call_deferred()
	updated_current.emit.call_deferred()
	
	updated_current.connect(changed.emit.call_deferred) # Emit changed after emitting updated current
	inventory.changed.connect(hold_current) # Hold current whenever inventory is changed
	
	if has_item_holder():
		item_holder.consumed_instance.connect(consume_instance)

func consume_instance(instance: ItemInstance) -> void:
	inventory.remove_item(instance.item, 1)
	changed.emit.call_deferred()

func has_item_holder() -> bool: return is_instance_valid(item_holder)

func scroll(direction: int, skip_null: bool=false) -> void:
	if not enabled:
		return
	
	if inventory == null:
		return
	
	var old_index := current_index
	current_index = wrapi(current_index + direction, 0, inventory.size)
	
	if skip_null:
		
		# Every slot is null
		if inventory.is_empty():
			return
		
		while get_current_instance() == null and current_index != old_index:
			scroll(direction, false)
	
	if current_index != old_index:
		updated_current.emit()

func get_current_instance() -> ItemInstance:
	if not enabled:
		return null
	if not inventory.is_index_valid(current_index):
		return null
	return inventory.get_instance(current_index)

func _process(_delta: float) -> void:
	if not enabled:
		return
	heed_num_key_input()
	heed_scroll_input()

func heed_scroll_input() -> void:
	if Input.is_action_just_pressed(scroll_up_input_action):
		scroll(-1)
	if Input.is_action_just_pressed(scroll_down_input_action):
		scroll(1)

func heed_num_key_input() -> void:
	for key in NUM_KEY_INDEX_MAP:
		if not Input.is_key_pressed(key):
			continue
		
		var index := NUM_KEY_INDEX_MAP[key]
		if index >= inventory.size:
			continue
		
		current_index = index
		updated_current.emit()
		return

func hold_current() -> void:
	if not enabled:
		return
	if not has_item_holder():
		return
	await get_tree().process_frame
	item_holder.update_item_instance(get_current_instance())
	changed.emit.call_deferred()
