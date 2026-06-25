extends Control

@export var crafting_environment: CraftingEnvironment
@export var craft_button: Button
@export var preview_rect: TextureRect
@export var preview_label: Label

func _ready() -> void:
	crafting_environment.grid_changed.connect(update)
	update()
	craft_button.pressed.connect(crafting_environment.craft)

func update() -> void:
	var recipe := RecipeBook.get_recipe(crafting_environment.get_recipe_layout())
	if recipe == null:
		craft_button.disabled = true
		preview_rect.texture = null
		preview_label.text = ""
		return
	
	craft_button.disabled = false
	preview_rect.texture = recipe.result.item.icon
	preview_label.text = "%s × %s" % [recipe.result.item.name, recipe.result.quantity]
