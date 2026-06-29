extends Resource
class_name RecipePanelGroup

@export var name: String
@export var icon: Texture

var type_entry: Control
var recipe_entries: Dictionary[ItemRecipe, Control]

func add_recipe(recipe: ItemRecipe, entry: Control) -> void:
	recipe_entries[recipe] = entry
