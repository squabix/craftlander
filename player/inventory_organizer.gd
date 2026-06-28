extends Node

const HOTBAR_INDEX := 0

@export var inventory: Inventory
@export var inventory_display_rows: Array[HBoxContainer]
@export var held_item_label: Label
@export var pause_interface: Control

@export_group("Selectors")
@export var primary_inventory_selector: InventorySelector
@export var secondary_inventory_selector: InventorySelector
@export var hold_inventory_selector: InventorySelector

func _ready() -> void:
	pause_interface.updated_pause.connect(update_selection_mode)
	
	# Not paused when game starts
	update_selection_mode(false)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("swap"):
		swap()

func swap() -> void:
	var primary_selection := primary_inventory_selector.selected_index
	var secondary_selection := secondary_inventory_selector.selected_index
	if inventory.swap(primary_selection, secondary_selection):
		if secondary_inventory_selector.get_current_instance() != null:
			primary_inventory_selector.selected_index = secondary_selection
		primary_inventory_selector.selected_new_index.emit(primary_inventory_selector.selected_index)

func get_hotbar_displays() -> Array[Node]:
	return inventory_display_rows[HOTBAR_INDEX].get_children() as Array[Node]

func get_all_displays() -> Array[ItemDisplay]:
	var all_displays: Array[ItemDisplay] = []
	for row in inventory_display_rows:
		all_displays.append_array(row.get_children())
	return all_displays

func update_selection_mode(paused_mode: bool) -> void:
	hold_inventory_selector.enabled = not paused_mode
	primary_inventory_selector.enabled = paused_mode
	secondary_inventory_selector.enabled = paused_mode
	held_item_label.visible = not paused_mode
