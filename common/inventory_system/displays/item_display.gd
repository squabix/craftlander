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
	var selected := is_selected()
	selection_modulate(selected)
	selection_scale(selected)
	
	var instance := get_instance()
	update_icon_texture(instance)
	update_quantity_label(instance)

func selection_modulate(selected: bool) -> void:
	modulate = selected_modulate if selected else unselected_modulate

func selection_scale(selected: bool) -> void:
	for target in selected_scale_targets:
		target.scale = target.scale.lerp(
			Vector2.ONE * (selected_scale_amount if selected else 1.0),
			selected_scale_speed
		)

func update_icon_texture(instance: ItemInstance) -> void:
	if icon_rect == null:
		return
	icon_rect.texture = null if instance == null or instance.item == null else instance.item.icon

func update_quantity_label(instance: ItemInstance) -> void:
	if quantity_label == null:
		return
	quantity_label.text = "" if instance == null or instance.quantity <= 1 else str(instance.quantity)
