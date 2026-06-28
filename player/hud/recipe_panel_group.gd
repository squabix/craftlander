extends Resource
class_name RecipePanelGroup

@export var name: String
@export var icon: Texture

var type_entry: Control
var recipe_entries: Array[Control]

func add_recipe(entry: Control) -> void:
	recipe_entries.append(entry)
