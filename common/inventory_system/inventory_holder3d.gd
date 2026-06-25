extends ItemHolder3D
class_name InventoryHolder3D

@export var selector: InventorySelector

var current_index: int

func _ready() -> void:
	selector.selected_new_index.connect(hold_index) # Hold current instance

func hold_index(index: int) -> void:
	current_index = index
	hold_instance(selector.inventory.get_instance(current_index))

func consume_item() -> void:
	selector.inventory.remove_instance(current_index, 1)
	consumed_instance.emit(held_item_instance)
	selector.changed.emit()

func _process(delta: float) -> void:
	super(delta)
	Util.interval_print(1.0, held_item_instance)
