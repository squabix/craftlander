extends Label

@export var primary_inventory_selector: InventorySelector
@export var secondary_inventory_selector: InventorySelector

func _ready() -> void:
	for selector in [primary_inventory_selector, secondary_inventory_selector]:
		selector.selected_instance_changed.connect(update_text.unbind(1))

func update_text() -> void:
	var primary_instance := primary_inventory_selector.get_current_instance()
	var secondary_instance := secondary_inventory_selector.get_current_instance()
	
	if primary_instance == null:
		if secondary_instance != null:
			text = secondary_instance.item.name
		else:
			text = "" # Both are empty
		return

	var primary_name: String = primary_instance.item.name

	# Check if secondary has a valid slot highlighted
	if secondary_inventory_selector.selected_index != -1 and secondary_instance != null:
		if primary_instance != secondary_instance:
			text = "%s → %s" % [primary_name, secondary_instance.item.name]
		else:
			text = primary_name
	else:
		text = primary_name
