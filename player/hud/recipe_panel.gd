extends Control

const LAYOUT_OFFSET := Vector2i(2, -3)

@export var recipe_list_box: VBoxContainer
@export var recipe_entry_template: Button
@export var recipe_display: RecipeDisplay
@export var back_button: Button

@export var icon_rect_path := "IconRect"

@export var recipe_groups: Dictionary[String, RecipePanelGroup]

func _ready() -> void:
	recipe_entry_template.hide()
	
	# Add all recipe entries
	for type in recipe_groups.keys():
		add_type_entry(type)
		
	for recipe in RecipeBook.all_recipes:
		add_recipe_entry(recipe)
	
	# Connect back button signal and move back button to end
	back_button.pressed.connect(show_types)
	recipe_list_box.move_child(back_button, recipe_list_box.get_child_count() - 1)
	
	show_types()

func add_type_entry(type: String) -> Button:
	var group := recipe_groups[type]
	
	var entry: Button = recipe_entry_template.duplicate()
	recipe_list_box.add_child(entry)
	entry.hide()
	
	set_icon(entry, group.icon)
	
	entry.text = type
	entry.pressed.connect(show_recipes.bind(type))
	group.type_entry = entry
	
	return entry

func hide_all() -> void:
	for entry in recipe_list_box.get_children():
		entry.hide()

func add_recipe_entry(recipe: ItemRecipe) -> Button:
	var item := recipe.result.item
	if not recipe_groups.has(item.type):
		printerr("%s cannot find recipe group of type %s and cannot add entry for %s" % [self, item.type, recipe])
		return
	
	var entry: Button = recipe_entry_template.duplicate()
	recipe_list_box.add_child(entry)
	entry.hide()
	
	entry.text = item.name
	set_icon(entry, item.icon)
	
	entry.pressed.connect(recipe_display.display.bind(recipe))
	recipe_groups[item.type].add_recipe(entry)
	return entry

func show_recipes(type: String) -> void:
	hide_all()
	var group: RecipePanelGroup = recipe_groups.get(type, null)
	if group == null:
		return
	for entry in group.recipe_entries:
		entry.show()
	back_button.show()

func show_types() -> void:
	hide_all()
	for group in recipe_groups.values():
		group.type_entry.show()

func set_icon(entry: Button, to: Texture) -> void:
	entry.get_node(icon_rect_path).texture = to
