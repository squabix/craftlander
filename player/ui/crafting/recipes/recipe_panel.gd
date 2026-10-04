extends VBoxContainer

const LAYOUT_OFFSET := Vector2i(2, -3)
const LOCKED_TEXT := "???"
const CATEGORY_COUNT_TEXT := "%s (%d/%d)"
const LOCKED_ICON_TINT := Color(0.0, 0.0, 0.0, 0.7)

@export var entry_container: VBoxContainer
@export var entry_template: Control
@export var recipe_display: RecipeDisplay
@export var recipe_learner: RecipeLearner
@export var back_entry: Control
@export var back_text := "Back"

@export var recipe_groups: Dictionary[StringName, RecipePanelGroup]

@export_group("Entry Node Paths")
@export var icon_rect_path := "IconRect"
@export var button_path := "Button"


func _ready() -> void:
	entry_template.hide()
	
	# Add all recipe and type entries
	for type in recipe_groups.keys():
		add_type_entry(type)
	for recipe in RecipeBook.all_recipes:
		add_recipe_entry(recipe)
	
	# Connect back button signal and move back button to end
	set_up_button(back_entry, back_text, show_types)
	entry_container.move_child(back_entry, entry_container.get_child_count() - 1)
	
	show_types()

func add_type_entry(type: StringName) -> Control:
	var group := recipe_groups[type]
	
	var entry := add_empty_entry()
	
	# Set up entry children
	set_icon(entry, group.icon)
	set_up_button(entry, group.name, show_recipes.bind(type))
	
	group.type_entry = entry
	return entry

func hide_all() -> void:
	for entry in entry_container.get_children():
		entry.hide()

func add_empty_entry() -> Control:
	var entry: Control = entry_template.duplicate()
	entry_container.add_child(entry)
	entry.hide()
	return entry

func add_recipe_entry(recipe: ItemRecipe) -> Control:
	var item := recipe.result.item
	
	if not recipe_groups.has(recipe.category):
		Util.node_error("%s cannot find recipe group of category %s and cannot add entry for %s", self, recipe.category, recipe)
		return
	
	var entry := add_empty_entry()
	
	# Set up entry children
	set_icon(entry, item.icon)
	set_up_button(entry, item.name, recipe_display.display.bind(recipe))
	
	recipe_groups[recipe.category].add_recipe(recipe, entry)
	return entry

func show_recipes(type: String) -> void:
	hide_all()
	var group: RecipePanelGroup = recipe_groups.get(type, null)
	if group == null:
		return
	for recipe in group.recipe_entries:
		var entry := group.recipe_entries[recipe]
		refresh_recipe_entry(recipe, entry)
		entry.show()
	back_entry.show()

func refresh_recipe_entry(recipe: ItemRecipe, entry: Control) -> void:
	var known := recipe in recipe_learner.known_recipes
	var button: Button = entry.get_node(button_path)
	button.text = recipe.result.item.name if known else LOCKED_TEXT
	button.disabled = not known
	var icon_rect: TextureRect = entry.get_node(icon_rect_path)
	icon_rect.modulate = Color.WHITE if known else LOCKED_ICON_TINT

func count_known_recipes(group: RecipePanelGroup) -> int:
	var count := 0
	for recipe in group.recipe_entries:
		if recipe in recipe_learner.known_recipes:
			count += 1
	return count

func set_up_button(entry: Control, text: String, pressed_callable: Callable) -> void:
	var button: Button = entry.get_node(button_path)
	if button == null:
		return
	button.text = text
	button.pressed.connect(pressed_callable)

func show_types() -> void:
	hide_all()
	for group in recipe_groups.values():
		if group.recipe_entries.is_empty():
			continue
		var button: Button = group.type_entry.get_node(button_path)
		button.text = CATEGORY_COUNT_TEXT % [group.name, count_known_recipes(group), group.recipe_entries.size()]
		group.type_entry.show()

func set_icon(entry: Control, to: Texture) -> void:
	var icon_rect: TextureRect = entry.get_node(icon_rect_path)
	if icon_rect == null:
		return
	icon_rect.texture = to
