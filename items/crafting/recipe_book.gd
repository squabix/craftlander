extends Node

var recipes: Array

func _ready() -> void:
	recipes = Util.find_all_resources("ItemRecipe", "res://items/")

func get_recipe(layout: Dictionary[Vector2i, Item]) -> ItemRecipe:
	for recipe in recipes:
		if do_layouts_match(layout, recipe.layout):
			return recipe
	return null

func do_layouts_match(a: Dictionary[Vector2i, Item], b: Dictionary[Vector2i, Item]) -> bool:
	for position in a:
		if not position in b:
			return false
		if not a[position].equals(b[position]):
			return false
	return true
