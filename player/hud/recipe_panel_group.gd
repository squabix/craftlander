extends Resource
class_name RecipePanelGroup

@export var icon: Texture

var type_entry: Button
var recipe_entries: Array[Button]

func add_recipe(entry: Button) -> void:
	recipe_entries.append(entry)
