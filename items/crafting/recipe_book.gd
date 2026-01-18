extends Node

var recipes: Array

func _ready() -> void:
	recipes = Util.find_all_resources("ItemRecipe", "res://items/")

func get_recipe(layout: Dictionary[Vector2i, Item]) -> ItemRecipe:
	for recipe in recipes:
		if verify_layout(layout, recipe.layout):
			return recipe
	return null

func verify_layout(layout: Dictionary[Vector2i, Item], correct_layout: Dictionary[Vector2i, Item]) -> bool:
	if layout.size() != correct_layout.size():
		return false
	
	layout = normalize_layout(layout)
	correct_layout = normalize_layout(correct_layout)
	
	for position in correct_layout:
		if not position in layout:
			return false
		if not correct_layout[position].equals(layout[position]):
			return false
	return true

func normalize_layout(layout: Dictionary[Vector2i, Item]) -> Dictionary[Vector2i, Item]:
	var min_x: int = layout.keys()[0].x
	var min_y: int = layout.keys()[0].y

	for pos in layout.keys():
		min_x = min(min_x, pos.x)
		min_y = min(min_y, pos.y)

	var normalized_layout: Dictionary[Vector2i, Item]
	for pos in layout.keys():
		normalized_layout[Vector2i(pos.x - min_x, pos.y - min_y)] = layout[pos]

	return normalized_layout
