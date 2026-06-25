extends Resource
class_name ItemInstance

signal emptied

@export var item: Item
@export var quantity := 1

func _init() -> void:
	make_unique.call_deferred()

func make_unique() -> void:
	if item != null and not item.is_unique:
		item = item.duplicate_deep()
		item.is_unique = true

func is_stackable_with(other_item: Item) -> bool: return item.equals(other_item) and quantity < item.max_quantity

func add(amount: int) -> int:
	if amount < 0:
		printerr("Cannot add negative amount to item - use subtract instead")
		breakpoint
		return amount
	var raw_quantity := quantity + amount
	var remainder: int = max(raw_quantity - item.max_quantity, 0)
	quantity = min(raw_quantity, item.max_quantity)
	return remainder

func subtract(amount: int) -> int:
	if amount < 0:
		printerr("Cannot subtract negative amount from item - use add instead")
		breakpoint
		return amount
	
	if quantity == 0:
		emptied.emit()
		return amount
	
	var raw_quantity := quantity - amount
	var remainder: int = min(raw_quantity, 0)
	quantity = max(raw_quantity, 0)
	if quantity == 0:
		emptied.emit()
	return remainder

func _to_string() -> String:
	return item.name + " * " + str(quantity)
