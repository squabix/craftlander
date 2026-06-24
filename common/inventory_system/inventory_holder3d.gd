extends ItemHolder3D
class_name InventoryHolder3D

@export var selector: InventorySelector

func _ready() -> void:
	selector.selected_new_item_instance.connect(hold_instance) # Hold current instance

func consume_item() -> void:
	selector.inventory.remove_instance(item_instance, 1)
	consumed_instance.emit(item_instance)
	selector.changed.emit()

func _process(delta: float) -> void:
	super(delta)
	Util.interval_print(1.0, item_instance)
