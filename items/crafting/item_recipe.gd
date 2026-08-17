class_name ItemRecipe
extends Resource

@export var result: ItemInstance
@export var indexed_layout: Dictionary[Vector2i, int]
@export var items: Array[Item]

var ingredients: Dictionary[Item, int]


func _init() -> void:
	ingredients.clear()
	# Populate ingredients dictionary
	for i in indexed_layout.values():
		if i < 0 or i >= items.size():
			push_error("%s cannot initialize recipe with nonexistant item at index %s" % [self, i])
			continue
		var item := items[i]
		if not is_instance_valid(item):
			continue
		if item in ingredients:
			ingredients[item] += 1
		else:
			ingredients[item] = 1


func _to_string() -> String:
	return str(result) + " Recipe"


func resolve_layout() -> Dictionary[Vector2i, Item]:
	var resolved: Dictionary[Vector2i, Item] = { }
	for position in indexed_layout:
		var index: int = indexed_layout[position]
		if index >= 0 and index < items.size() and is_instance_valid(items[index]):
			resolved[position] = items[index]
	return resolved

func get_item(position: Vector2i) -> Item:
	var index: int = indexed_layout.get(position, -1)
	if index == -1:
		push_error("%s cannot find position %s in layout" % [self, position])
		return null
	if index > ingredients.size():
		push_error("%s cannot get nonexistant item at index %s" % [self, index])
		return null
	return items[index]
