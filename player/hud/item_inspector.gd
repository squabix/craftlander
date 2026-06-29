extends Control

@export var inventory_selector: InventorySelector
@export var name_label: Label
@export var info_label: Label
@export var container: Control
@export var mouse_offset: Vector2

func _ready() -> void:
	inventory_selector.selected_instance_changed.connect(inspect_instance)

func _process(_delta: float) -> void:
	if inventory_selector.selected_index == -1 or inventory_selector.get_current_instance() == null:
		hide()
		return
	
	show()
	global_position = get_global_mouse_position() + Vector2.UP * size.y + mouse_offset

func inspect_instance(instance: ItemInstance) -> void:
	if instance == null:
		hide()
		return
	
	name_label.text = str(instance)
	info_label.text = get_info(instance.item)
	
	reset_size()

func get_info(item: Item) -> String:
	if item == null:
		return ""
	
	var info := ""
	info += "Type: %s" % item.type
	if item is HarvestingTool:
		if item.damage != null:
			info += "\nDamage: %s" % item.damage.base_amount
	return info
