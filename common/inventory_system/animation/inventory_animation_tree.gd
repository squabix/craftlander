extends ItemAnimationTree
class_name InventoryAnimationTree

@export var inventory_selector: InventorySelector

func _ready() -> void:
	super()
	
	# Update when inventory selector selects new instance
	if is_instance_valid(inventory_selector):
		inventory_selector.selected_instance_changed.connect(update_to_selection.unbind(1))
		update_to_selection()

func update_to_selection() -> void:
	if not is_instance_valid(inventory_selector):
		printerr("%s cannot update to selection with invalid inventory selector")
		return
	update_item(inventory_selector.get_current_item())
