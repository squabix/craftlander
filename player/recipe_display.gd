extends Control
class_name RecipeDisplay

const TEXTURE_SIZE := Vector2i(30, 30)
const DEFAULT_LABEL_TEXT := "Select a Recipe from Recipe Book"
const LAYOUT_OFFSET := Vector2i(2, -3)

@export var grid_container: VBoxContainer
@export var recipe_label: Label
@export var recipe_text := "%s Recipe"


func _ready() -> void:
	for row in grid_container.get_children():
		for container in row.get_children():
			var rect: TextureRect = container.get_child(0)
			rect.custom_minimum_size = TEXTURE_SIZE
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	clear()

func clear() -> void:
	recipe_label.text = DEFAULT_LABEL_TEXT
	for row in grid_container.get_children():
		for container in row.get_children():
			container.get_child(0).texture = null

func display(recipe: ItemRecipe) -> void:
	clear()
	recipe_label.text = recipe_text % recipe.result.item.name
	for item_position in recipe.layout:
		if recipe.layout[item_position] == null:
			printerr(self, " cannot display ingredient in ", recipe, " with null at ", item_position)
			continue
		get_grid_item_texture_rect(item_position).texture = recipe.layout[item_position].icon

func get_grid_item_texture_rect(rect_position: Vector2i) -> TextureRect:
	var row := grid_container.get_child(-rect_position.y + LAYOUT_OFFSET.y)
	return row.get_child(rect_position.x + LAYOUT_OFFSET.x).get_child(0)
