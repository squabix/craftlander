extends Control

const LAYOUT_OFFSET := Vector2i(2, -3)

@onready var recipe_list_box: VBoxContainer = $RecipeList/RecipeListBox
@onready var recipe_entry_template: Button = $RecipeList/RecipeListBox/RecipeEntry

@onready var grid_container: VBoxContainer = $RecipeDisplay/GridContainer

func _ready() -> void:
	recipe_entry_template.hide()
	for recipe in RecipeBook.all_recipes:
		var new_entry: Button = recipe_entry_template.duplicate()
		recipe_list_box.add_child(new_entry)
		new_entry.show()
		new_entry.text = recipe.result.item.name
		new_entry.get_node("IconRect").texture = recipe.result.item.icon
		new_entry.pressed.connect(display_recipe.bind(recipe))

func clear_recipe_display() -> void:
	for row in grid_container.get_children():
		for label in row.get_children():
			label.text = ""

func display_recipe(recipe: ItemRecipe) -> void:
	clear_recipe_display()
	for item_position in recipe.layout:
		if recipe.layout[item_position] == null:
			printerr(self, " cannot display ingredient in ", recipe, " with null at ", item_position)
			continue
		get_grid_item_label(item_position).text = recipe.layout[item_position].name

func get_grid_item_label(label_position: Vector2i) -> Label:
	var row := grid_container.get_child(-label_position.y + LAYOUT_OFFSET.y)
	return row.get_child(label_position.x + LAYOUT_OFFSET.x)
