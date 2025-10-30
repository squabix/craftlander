extends Node3D
class_name ItemHolder3D

signal used_item(item: Item)
signal consumed_instance(instance: ItemInstance)

@export var sprite: Sprite3D
@export var item_instance: ItemInstance
@export var instance_parent: Node3D
@export var item_override: Item

func get_item() -> Item:
	if item_override != null:
		return item_override
	if item_instance == null:
		return null
	return item_instance.item

func has_item() -> bool:
	return item_instance != null and item_instance.item != null

func set_instance(to: ItemInstance) -> void:
	if has_item():
		var old_item: Item = get_item()
		if item_instance != null and is_instance_valid(old_item.scene_instance):
			instance_parent.remove_child.call_deferred(old_item.scene_instance)
	item_instance = to
	
	if item_instance == null or item_instance.item == null:
		sprite.texture = null
		return
	
	sprite.texture = item_instance.item.icon
	if item_instance.item.scene != null:
		instance_parent.add_child.call_deferred(item_instance.item.instantiate_scene())

func use_item() -> void:
	if item_instance == null or item_instance.item == null:
		return
	if item_instance.item.use() and item_instance.item.consumable:
		consumed_instance.emit(item_instance)
	used_item.emit(item_instance.item)

func _ready() -> void:
	set_instance(item_instance)

func _process(delta: float) -> void:
	if not has_item():
		return
	get_item().update(delta)
