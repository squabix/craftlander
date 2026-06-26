extends Control

const LAYOUT_OFFSET := Vector2i(2, -3)

@export var recipe_list_box: VBoxContainer
@export var recipe_entry_template: Button
@export var recipe_display: RecipeDisplay

@export var icon_rect_path := "IconRect"

func _ready() -> void:
	#recipe_entry_template.hide()
	for recipe in RecipeBook.all_recipes:
		add_entry(recipe)
		print("Adding entry: %s" % recipe)

func add_entry(recipe: ItemRecipe) -> Button:
	var entry: Button = recipe_entry_template.duplicate()
	recipe_list_box.add_child(entry)
	entry.show()
	entry.text = recipe.result.item.name
	entry.get_node(icon_rect_path).texture = recipe.result.item.icon
	entry.pressed.connect(recipe_display.display.bind(recipe))
	return entry
