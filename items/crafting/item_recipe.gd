extends Resource
class_name ItemRecipe

@export var result: ItemInstance
@export var layout: Dictionary[Vector2i, Item]

var ingredients: Dictionary[Item, int]

func _init() -> void:
	
	# Populate ingredients dictionary
	for item in layout.values():
		if item in ingredients:
			ingredients[item] += 1
		else:
			ingredients[item] = 1

func _to_string() -> String:
	return str(result) + " Recipe"
