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
	for position in correct_layout:
		if not position in layout:
			return false
		if not correct_layout[position].equals(layout[position]):
			return false
	return true
