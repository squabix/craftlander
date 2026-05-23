extends Control

const LAYOUT_OFFSET := Vector2i(2, -3)

@export var recipe_list_box: VBoxContainer
@export var recipe_entry_template: Button
@export var grid_container: VBoxContainer
@export var icon_rect_path := "IconRect"

func _ready() -> void:
	recipe_entry_template.hide()
	for recipe in RecipeBook.all_recipes:
		add_entry(recipe)

func add_entry(recipe: ItemRecipe) -> Button:
	var entry: Button = recipe_entry_template.duplicate()
	recipe_list_box.add_child(entry)
	entry.show()
	entry.text = recipe.result.item.name
	entry.get_node(icon_rect_path).texture = recipe.result.item.icon
	entry.pressed.connect(display_recipe.bind(recipe))
	return entry

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
