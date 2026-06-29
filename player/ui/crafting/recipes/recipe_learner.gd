extends Node
class_name RecipeLearner

@export var inventory: Inventory
@export var all_recipe_discoveries: Array[RecipeDiscovery]
@export var known_recipes: Array[ItemRecipe]

var remaining_discoveries: Array[RecipeDiscovery]

func _ready() -> void:
	inventory.item_changed.connect(func(index: int) -> void: discover_item(inventory.get_item(index)))
	remaining_discoveries = all_recipe_discoveries.duplicate()

func discover_item(item: Item) -> void:
	
	# Confirm item has corresponding discovery
	var matched_discovery := match_discovery(item)
	if matched_discovery == null:
		return
	
	add_recipies(matched_discovery.discovered_recipes)
	remaining_discoveries.erase(matched_discovery)

func add_recipies(recipies: Array[ItemRecipe]) -> void:
	for recipe in recipies:
		if recipe in known_recipes:
			continue
		known_recipes.append(recipe)

func match_discovery(item: Item) -> RecipeDiscovery:
	for discovery in remaining_discoveries:
		if discovery.matches(item):
			return discovery
	return null
