extends ItemHolder3D
class_name InventoryHolder3D

@export var selector: InventorySelector

func _ready() -> void:
	selector.updated.connect(hold_selected_instance)

func hold_selected_instance() -> void:
	hold_instance(selector.get_current_instance())

func consume_item() -> void:
	selector.inventory.remove_instance(item_instance, 1)
	consumed_instance.emit(item_instance)
	selector.changed.emit()

func _process(delta: float) -> void:
	super(delta)
	Util.interval_print(1.0, item_instance)
