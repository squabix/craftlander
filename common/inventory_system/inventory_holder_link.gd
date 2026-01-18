extends Node
class_name InventoryHolderLink

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

@export var inventory: Inventory
@export var item_holder: ItemHolder3D
@export var root: Node
@export var current_index := 0:
	set(to):
		if current_index == to:
			hold_current()
			return
		current_index = wrapi(to, 0, inventory.size)
		hold_current()
		updated_current.emit()

@export_group("Input")
@export var use_num_key_input := true
@export var scroll_up_input_action := ""
@export var scroll_down_input_action := ""

func _ready() -> void:
	if inventory == null:
		printerr(name, " has no inventory and will not function")
		return
	
	if not is_instance_valid(item_holder):
		printerr(name, " has an invalid ItemHolder and will not function")
		return
	
	hold_current.call_deferred()
	updated_current.emit.call_deferred()
	updated_current.connect(
		func():
			await get_tree().process_frame
			changed.emit()
	)
	inventory.changed.connect(
		func():
			hold_current()
			await get_tree().process_frame
			changed.emit()
	)
	item_holder.consumed_instance.connect(
		func(instance: ItemInstance):
			inventory.remove_item(instance.item, 1)
			changed.emit.call_deferred()
	)
	

func scroll(direction: int, skip_null: bool=false) -> void:
	if inventory == null:
		return
	
	var old_index := current_index
	current_index = wrapi(current_index + direction, 0, inventory.size)
	
	if skip_null:
		while get_current_instance() == null and current_index != old_index:
			scroll(direction, false)
	
	if current_index != old_index:
		updated_current.emit()

func get_current_instance() -> ItemInstance:
	#current_index = clampi(current_index, 0, inventory.size)
	if not inventory.is_index_valid(current_index):
		return null
	return inventory.get_instance(current_index)

func _process(_delta: float) -> void:
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
	item_holder.item_instance = get_current_instance()
