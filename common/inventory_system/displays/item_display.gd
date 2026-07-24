class_name ItemDisplay
extends Control

enum SelectMode { PRESS, HOVER, MANUAL }
enum LabelMode { QUANTITY, FULL_STRING }

@export var instance_override: ItemInstance
@export var hide_when_empty := false

@export_group("Index")
@export var index := 0

@export_subgroup("Auto Set", "auto_set_index")
@export var auto_set_index_enabled := false
@export var auto_set_index_offset := 0

@export_group("Selection")

@export_subgroup("Components")
@export var inventory_selectors: Dictionary[InventorySelector, SelectMode]
@export var select_button: Button

@export_subgroup("Modulate", "modulate")
@export var modulate_unselected := Color.WHITE
@export var modulate_selected := Color.WHITE

@export_subgroup("Selected Scale", "selected_scale")
@export var selected_scale_amount := 1.0
@export_range(0.0, 1.0) var selected_scale_speed := 1.0
@export var selected_scale_targets: Array[Control] = []

@export_group("Fraction", "fraction")
@export var fraction_number := 0
@export var fraction_is_flipped := false

@export_subgroup("Texture", "fraction_texture")
@export var fraction_texture_rect: TextureRect
@export var fraction_texture_sufficient: Texture2D
@export var fraction_texture_sufficient_modulate := Color.WHITE
@export var fraction_texture_insufficient: Texture2D
@export var fraction_texture_insufficient_modulate := Color.WHITE

@export var fraction_suffix := "/%s"
@export var fraction_progress_bar: ProgressBar

@export_group("Components")
@export var inventory: Inventory

@export var icon_rect: TextureRect
@export_subgroup("Icon Rect Settings", "icon_rect")
@export var icon_rect_empty_texture: Texture2D

@export var label: Label
@export_subgroup("Label Settings", "label")
@export var label_mode := LabelMode.QUANTITY
@export var label_format := "%s"
@export var label_empty_text := ""

func _ready() -> void:
	# Auto set index
	if auto_set_index_enabled:
		index = get_index() + auto_set_index_offset

	# Connect selection signal
	if is_instance_valid(select_button):
		select_button.pressed.connect(press)
		select_button.mouse_entered.connect(hover)
		select_button.mouse_exited.connect(unhover)


func _process(_delta: float) -> void:
	var selected := is_selected()
	selection_modulate(selected)
	selection_scale(selected)
	
	var instance := get_instance()
	visible = not (instance == null and hide_when_empty)
	update_icon_texture(instance)
	update_quantity_label(instance)
	update_fraction_rect(instance)
	update_fraction_progress_bar(instance)


func update_fraction_progress_bar(instance: ItemInstance) -> void:
	if not is_instance_valid(fraction_progress_bar):
		return
	fraction_progress_bar.max_value = get_denominator(instance)
	fraction_progress_bar.value = get_numerator(instance)


func select_self(inventory_selector: InventorySelector) -> bool:
	if inventory_selector == null:
		return false
	if inventory_selector.enabled == false:
		return false
	inventory_selector.selected_index = index
	return true


func deselect_self(inventory_selector: InventorySelector) -> bool:
	if inventory_selector == null:
		return false
	if inventory_selector.enabled == false:
		return false
	if inventory_selector.selected_index != index:
		return false
	inventory_selector.selected_index = -1
	return true


func press() -> void:
	for selector in inventory_selectors:
		if inventory_selectors[selector] == SelectMode.PRESS:
			select_self(selector)


func hover() -> void:
	for selector in inventory_selectors:
		if inventory_selectors[selector] == SelectMode.HOVER:
			select_self(selector)


func unhover() -> void:
	for selector in inventory_selectors:
		if inventory_selectors[selector] == SelectMode.HOVER:
			deselect_self(selector)


func get_instance() -> ItemInstance:
	if instance_override:
		return instance_override
	if inventory == null:
		return null
	return inventory.get_instance(index)


func get_item() -> Item:
	var instance := get_instance()
	if instance == null:
		return null
	return instance.item


func is_selected() -> bool:
	for selector in inventory_selectors:
		if selector.enabled and selector.selected_index == index:
			return true
	return false


func selection_modulate(selected: bool) -> void:
	modulate = modulate_selected if selected else modulate_unselected


func get_numerator(instance: ItemInstance) -> int:
	if not is_fraction_valid(instance):
		return 1
	return fraction_number if fraction_is_flipped else instance.quantity


func get_denominator(instance: ItemInstance) -> int:
	if not is_fraction_valid(instance):
		return 1
	return instance.quantity if fraction_is_flipped else fraction_number


func selection_scale(selected: bool) -> void:
	for target in selected_scale_targets:
		target.scale = target.scale.lerp(
			Vector2.ONE * (selected_scale_amount if selected else 1.0),
			selected_scale_speed,
		)


func is_fraction_valid(instance: ItemInstance) -> bool:
	if instance == null:
		return false
	if fraction_is_flipped:
		return instance.quantity > 0
	return fraction_number > 0


func is_quantity_sufficient(instance: ItemInstance) -> bool:
	if not is_fraction_valid(instance):
		return false
	return get_numerator(instance) >= get_denominator(instance)


func update_fraction_rect(instance: ItemInstance) -> void:
	if not is_instance_valid(fraction_texture_rect):
		return
	if not is_fraction_valid(instance):
		fraction_texture_rect.texture = null
		return
	var sufficient := is_quantity_sufficient(instance)
	
	fraction_texture_rect.modulate = fraction_texture_sufficient_modulate if sufficient else fraction_texture_insufficient_modulate
	fraction_texture_rect.texture = fraction_texture_sufficient if sufficient else fraction_texture_insufficient


func update_icon_texture(instance: ItemInstance) -> void:
	if icon_rect == null:
		return
	icon_rect.texture = icon_rect_empty_texture if instance == null or instance.item == null else instance.item.icon


func update_quantity_label(instance: ItemInstance) -> void:
	if label == null:
		return
	if instance == null:
		label.text = label_empty_text
		return
	match label_mode:
		LabelMode.QUANTITY:
			if fraction_is_flipped:
				label.text = label_format % str(fraction_number) + fraction_suffix % instance.quantity
			else:
				var qty_str := "" if (instance.quantity <= 1 and fraction_number <= 0) else str(instance.quantity)
				var frac_str := fraction_suffix % fraction_number if fraction_number > 0 else ""
				label.text = label_format % qty_str + frac_str
		LabelMode.FULL_STRING:
			var start := label_format % (instance.item.instantiate(fraction_number) if fraction_is_flipped else instance)
			var end := fraction_suffix % instance.quantity if fraction_is_flipped else fraction_suffix % fraction_number if fraction_number > 0 else ""
			label.text = start + end
