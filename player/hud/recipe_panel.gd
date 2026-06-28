extends VBoxContainer

const LAYOUT_OFFSET := Vector2i(2, -3)

@export var entry_container: VBoxContainer
@export var entry_template: Control
@export var recipe_display: RecipeDisplay
@export var recipe_learner: RecipeLearner
@export var back_entry: Control
@export var back_text := "Back"

@export var recipe_groups: Dictionary[String, RecipePanelGroup]

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

func add_type_entry(type: String) -> Control:
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
	
	if not recipe_groups.has(item.type):
		printerr("%s cannot find recipe group of type %s and cannot add entry for %s" % [self, item.type, recipe])
		return
	
	var entry := add_empty_entry()
	
	# Set up entry children
	set_icon(entry, item.icon)
	set_up_button(entry, item.name, recipe_display.display.bind(recipe))
	
	recipe_groups[item.type].add_recipe(recipe, entry)
	return entry

func show_recipes(type: String) -> void:
	hide_all()
	var group: RecipePanelGroup = recipe_groups.get(type, null)
	if group == null:
		return
	for recipe in recipe_learner.known_recipes:
		if not recipe in group.recipe_entries.keys():
			continue
		group.recipe_entries[recipe].show()
	back_entry.show()

func set_up_button(entry: Control, text: String, pressed_callable: Callable) -> void:
	var button: Button = entry.get_node(button_path)
	if button == null:
		return
	button.text = text
	button.pressed.connect(pressed_callable)

func show_types() -> void:
	hide_all()
	for group in recipe_groups.values():
		for known_recipe in recipe_learner.known_recipes:
			if group.recipe_entries.has(known_recipe):
				group.type_entry.show()
				break

func set_icon(entry: Control, to: Texture) -> void:
	var icon_rect: TextureRect = entry.get_node(icon_rect_path)
	if icon_rect == null:
		return
	icon_rect.texture = to
