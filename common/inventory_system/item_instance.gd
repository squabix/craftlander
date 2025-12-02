extends Resource
class_name ItemInstance

signal emptied

@export var item: Item

@export var quantity := 1

func _init() -> void:
	make_unique.call_deferred()

func make_unique() -> void:
	if item != null:
		item = item.duplicate_deep()

static func do_items_match(items: Array[Item]) -> bool:
	for a in items:
		for b in items:
			if a == b:
				continue
			if not (a.matches(b) and b.matches(a)):
				return false
	return true

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
	print("New amount: " + str(quantity))
	return remainder

func _to_string() -> String:
	return item.name + " * " + str(quantity)

func matches(item: Item) -> bool:
	return do_attributes_match(item)

func do_attributes_match(item: Item) -> bool:
	return self.attributes == item.attributes
