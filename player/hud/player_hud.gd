extends Control

const HOTBAR_INDEX := 0

@export var inventory_display_rows: Array[HBoxContainer]
@export var primary_inventory_selector: InventorySelector
@export var hold_inventory_selector: InventorySelector
@export var pause_interface: Control

func _ready() -> void:
	pause_interface.updated_pause.connect(update_selection_mode)
	
	for display in get_all_displays():
		display.inventory_selector = primary_inventory_selector
	
	# Not paused when game starts
	update_selection_mode(false)

func get_hotbar_displays() -> Array[Node]:
	return inventory_display_rows[HOTBAR_INDEX].get_children() as Array[Node]

# Only hotbar changes inventory selector
# Other displays can ignore the holding selector
func update_hotbar_display(selector: InventorySelector) -> void:
	for display in get_hotbar_displays():
		display.inventory_selector = selector

func get_all_displays() -> Array[ItemDisplay]:
	var all_displays: Array[ItemDisplay] = []
	for row in inventory_display_rows:
		all_displays.append_array(row.get_children())
	return all_displays

func update_selection_mode(paused_mode: bool) -> void:
	hold_inventory_selector.enabled = not paused_mode
	primary_inventory_selector.enabled = paused_mode
	update_hotbar_display(primary_inventory_selector if paused_mode else hold_inventory_selector)
