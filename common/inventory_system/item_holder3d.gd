extends Node3D
class_name ItemHolder3D

signal updated_instance(new_instance: ItemInstance)
signal used_item(item: Item)
signal consumed_instance(instance: ItemInstance)
signal item_event_triggered(event: ItemEvent)

@export var initial_item_instance: ItemInstance
@export var root: Node
@export_group("Misc")
@export var anim_tree: ItemAnimationTree
@export var instance_parent: Node3D

var item_instance: ItemInstance

func update_item_instance(to: ItemInstance):
	if item_instance == to: return # Already holding this instance
	
	if instance_parent == null:
		instance_parent = self
	reset_item_instance()
	
	item_instance = to
	if item_instance == null: return
	
	await item_instance.item.ensure_unique()
	if anim_tree:
		anim_tree.update_item(item_instance.item)
	item_instance.item.root = root
	
	# Add item scene
	if item_instance.item.scene != null:
		item_instance.item.add_scene(instance_parent)
	
	updated_instance.emit(item_instance)
	
	connect_triggered_event(item_instance)

func connect_triggered_event(instance: ItemInstance) -> void:
	if instance == null or instance.item == null:
		return
	var triggered_event := instance.item.triggered_event
	var emit := item_event_triggered.emit
	if triggered_event.is_connected(emit):
		return
	triggered_event.connect(emit)

func reset_item_instance() -> void:
	if not has_item():
		return
	item_instance.item.remove_scene()
	item_instance = null

func has_item() -> bool:
	return item_instance != null and item_instance.item != null

func use_item() -> void:
	if item_instance == null or item_instance.item == null:
		return
	used_item.emit(item_instance.item)
	var consumed := item_instance.item.use()
	if consumed and item_instance.item.consumable:
		consumed_instance.emit(item_instance)

func _ready() -> void:
	if initial_item_instance != null:
		initial_item_instance = initial_item_instance.duplicate_deep()
		initial_item_instance.make_unique()
	update_item_instance(initial_item_instance)

func _process(delta: float) -> void:
	if not has_item():
		return
	item_instance.item.update(delta)
