extends ItemHolder3D
class_name InventoryHolder3D

@export var selector: InventorySelector

var current_index: int

func _ready() -> void:
	selector.selected_new_index.connect(func(index: int): current_index = index)
	
	selector.selected_instance_changed.connect(hold_instance)
	
	current_index = selector.selected_index
	hold_instance(selector.get_current_instance())

func consume_item() -> void:
	selector.inventory.remove_instance(current_index, 1)
	consumed_instance.emit(held_item_instance)
