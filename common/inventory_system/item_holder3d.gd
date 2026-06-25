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

var held_item_instance: ItemInstance

func hold_instance(new_instance: ItemInstance) -> void:
	if held_item_instance == new_instance:
		return # Already holding this instance
	
	if instance_parent == null:
		instance_parent = self
	reset_instance()
	
	held_item_instance = new_instance
	if held_item_instance == null:
		return
	
	await held_item_instance.item.ensure_unique()
	if anim_tree:
		anim_tree.update_item(held_item_instance.item)
	held_item_instance.item.root = root
	
	# Add item scene
	if held_item_instance.item.scene != null:
		held_item_instance.item.add_scene(instance_parent)
	
	updated_instance.emit(held_item_instance)
	
	connect_triggered_event(held_item_instance)
	print("Success")

func connect_triggered_event(instance: ItemInstance) -> void:
	if instance == null or instance.item == null:
		return
	var triggered_event := instance.item.triggered_event
	var emit := item_event_triggered.emit
	if triggered_event.is_connected(emit):
		return
	triggered_event.connect(emit)

func reset_instance() -> void:
	if not has_item():
		return
	held_item_instance.item.remove_scene()
	held_item_instance = null

func has_item() -> bool:
	return held_item_instance != null and held_item_instance.item != null

func use_item() -> void:
	if held_item_instance == null or held_item_instance.item == null:
		return
	used_item.emit(held_item_instance.item)
	var consumed := held_item_instance.item.use()
	if consumed and held_item_instance.item.consumable:
		consume_item()

func consume_item() -> void:
	consumed_instance.emit(held_item_instance)

func _ready() -> void:
	if initial_item_instance != null:
		initial_item_instance = initial_item_instance.duplicate_deep()
		initial_item_instance.make_unique()
	hold_instance(initial_item_instance)

func _process(delta: float) -> void:
	if not has_item():
		return
	held_item_instance.item.update(delta)
