extends Control
class_name ItemDisplay

@export var icon_rect: TextureRect
@export var quantity_label: Label
@export var inventory: Inventory
@export var index: int = 0
@export var instance_override: ItemInstance

@export_group("Selection")
@export var inventory_holder_link: InventoryHolderLink
@export var unselected_modulate: Color = Color.WHITE
@export var selected_modulate: Color = Color.WHITE

func get_instance() -> ItemInstance:
	if instance_override:
		return instance_override
	
	if inventory == null:
		return null
	
	return inventory.get_instance(index)

func is_selected() -> bool:
	if inventory_holder_link == null:
		return false
	return inventory_holder_link.current_index == index

func _process(_delta: float) -> void:
	modulate = selected_modulate if is_selected() else unselected_modulate
	
	var instance: ItemInstance = get_instance()
	if instance == null:
		icon_rect.texture = null
		quantity_label.text = ""
		return
	
	icon_rect.texture = instance.item.icon
	if instance.quantity > 1:
		quantity_label.text = str(instance.quantity)
	else:
		quantity_label.text = ""
