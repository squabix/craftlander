extends ItemDisplay

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
		instance_override = null
		return
	
	craft_button.disabled = false
	instance_override = recipe.result
