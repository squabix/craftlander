extends Node3D
class_name ItemHolder3D

signal updated_instance(new_instance: ItemInstance)
signal used_item(item: Item)
signal consumed_instance(instance: ItemInstance)
signal item_event_triggered(event: ItemEvent)

@export var icon_sprite: Sprite3D
@export var instance_parent: Node3D
@export var item_override: Item
@export var root: Node
@export var item_instance: ItemInstance:
	set(to):
		if item_instance == to:
			return
		
		if instance_parent == null:
			instance_parent = self
		
		# Remove old item
		if has_item():
			if item_instance != null:
				item_instance.item.remove_scene()
		item_instance = to
		
		if item_instance == null or item_instance.item == null:
			update_icon(null)
			return
		
		update_icon(item_instance.item.icon)
		item_instance.item.root = root
		if item_instance.item.scene != null:
			item_instance.item.add_scene(instance_parent)
			#instance_parent.add_child.call_deferred(item_instance.item.instantiate_scene())
		
		updated_instance.emit(item_instance)
		if not item_instance.item.triggered_event.is_connected(item_event_triggered.emit):
			item_instance.item.triggered_event.connect(item_event_triggered.emit)

var item: Item:
	get:
		if item_override != null:
			return item_override
		if item_instance == null:
			return null
		return item_instance.item

func has_item() -> bool:
	return item_instance != null and item_instance.item != null

func update_icon(to: Texture) -> void:
	if not is_instance_valid(icon_sprite):
		return
	icon_sprite.texture = to

func use_item() -> void:
	if item_instance == null or item_instance.item == null:
		return
	used_item.emit(item_instance.item)
	if item_instance.item.use() and item_instance.item.consumable:
		consumed_instance.emit(item_instance)

func _ready() -> void:
	if item_override:
		item_instance = item_override.get_instance()
	else:
		item_instance = item_instance

func _process(delta: float) -> void:
	if not has_item():
		return
	item.update(delta)
