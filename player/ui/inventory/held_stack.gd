class_name HeldStack
extends Node

signal changed

@export var inventory: Inventory
@export var dropper: InventoryDropper3D
@export var pause_interface: PauseMenu
@export var quantity_label: Label

@export_group("Label")
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var label_offset := Vector2(8.0, 8.0)

var instance: ItemInstance


func _ready() -> void:
	pause_interface.updated_pause.connect(on_pause_updated)
	pause_interface.before_save.connect(return_to_inventory)
	changed.connect(update_label)
	update_label()


func _process(_delta: float) -> void:
	if not is_instance_valid(quantity_label) or not quantity_label.visible:
		return

	quantity_label.global_position = quantity_label.get_global_mouse_position() + label_offset


func is_empty() -> bool:
	return instance == null


func click(target: Inventory, index: int) -> void:
	if target.constant or not target.has_index(index):
		return

	if instance == null:
		set_held(target.empty_instance(index))
		return

	var slot := target.get_instance(index)
	if slot == null:
		target.set_instance(index, instance)
		set_held(null)
		return

	if slot.item.equals(instance.item):
		set_held(target.merge_instance_into(index, instance))
		return

	var picked := target.empty_instance(index)
	target.set_instance(index, instance)
	set_held(picked)


func secondary_click(target: Inventory, index: int) -> void:
	if target.constant or not target.has_index(index):
		return

	if instance == null:
		set_held(target.split_half(index))
		return

	var single := instance.item.instantiate(1)
	if target.merge_instance_into(index, single) != null:
		return

	instance.quantity -= 1
	set_held(instance if instance.quantity > 0 else null)


func take_one() -> Item:
	if instance == null:
		return null

	var item := instance.item
	instance.quantity -= 1
	set_held(instance if instance.quantity > 0 else null)
	return item


func try_add_one(item: Item) -> bool:
	if instance == null or not instance.item.equals(item) or instance.quantity >= instance.item.max_quantity:
		return false

	instance.quantity += 1
	set_held(instance)
	return true


func return_to(target: Inventory) -> ItemInstance:
	var held := instance
	set_held(null)
	if held == null:
		return null

	var leftover := target.add_item(held.item, held.quantity)
	return held.item.instantiate(leftover) if leftover > 0 else null


func return_to_inventory() -> void:
	var leftover := return_to(inventory)
	if leftover == null:
		return

	drop_leftover(leftover.item, leftover.quantity)


func drop_leftover(item: Item, quantity: int) -> void:
	for count in quantity:
		dropper.add_pickup(item)


func on_pause_updated(paused: bool) -> void:
	if not paused:
		return_to_inventory()


func set_held(to: ItemInstance) -> void:
	instance = to
	changed.emit()


func update_label() -> void:
	if not is_instance_valid(quantity_label):
		return

	var has_quantity := instance != null and instance.quantity > 1
	quantity_label.visible = has_quantity
	if has_quantity:
		quantity_label.text = str(instance.quantity)
