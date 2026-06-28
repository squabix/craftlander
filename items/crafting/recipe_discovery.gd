extends Resource
class_name RecipeDiscovery

@export var item: Item
@export var discovered_recipes: Array[ItemRecipe]

func matches(other_item: Item) -> bool: return item.equals(other_item)
