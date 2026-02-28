extends Control
class_name ItemDisplay

@export var icon_rect: TextureRect
@export var quantity_label: Label
@export var inventory: Inventory
@export var index := 0
@export var auto_set_index := false
@export var instance_override: ItemInstance

@export_group("Selection")
@export var inventory_holder_link: InventoryHolderLink
@export var select_button: Button
@export var unselected_modulate := Color.WHITE
@export var selected_modulate := Color.WHITE
@export var selected_scale_amount := 1.0
@export_range(0.0, 1.0) var selected_scale_speed := 1.0
@export var selected_scale_targets: Array[Control] = []

func _ready() -> void:
	if auto_set_index:
		index = get_index()
	if is_instance_valid(select_button):
		select_button.pressed.connect(select_self)

func select_self() -> void:
	inventory_holder_link.current_index = index

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
	for target in selected_scale_targets:
		target.scale = target.scale.lerp(
			Vector2.ONE * (selected_scale_amount if is_selected() else 1.0),
			selected_scale_speed
		)
	
	var instance := get_instance()
	if instance == null:
		icon_rect.texture = null
		quantity_label.text = ""
		return
	
	if instance.item != null:
		icon_rect.texture = instance.item.icon
	
	if instance.quantity > 1:
		quantity_label.text = str(instance.quantity)
	else:
		quantity_label.text = ""
