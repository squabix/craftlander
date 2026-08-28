extends Menu
class_name TitleScreen

@export_group("Submenus")
@export var save_submenu: SaveMenu
@export var settings_submenu: Menu


@export_group("Main Buttons")
@export var new_game_button: Button
@export var load_game_button: Button
@export var settings_button: Button
@export var quit_button: Button

func _ready() -> void:
	super()
	new_game_button.pressed.connect(start_save_selection.bind(SaveMenu.SelectMode.NEW))
	load_game_button.pressed.connect(start_save_selection.bind(SaveMenu.SelectMode.LOAD))
	settings_button.pressed.connect(open_submenu.bind(settings_submenu))
	quit_button.pressed.connect(get_tree().quit)

func start_save_selection(mode: SaveMenu.SelectMode) -> void:
	save_submenu.current_select_mode = mode
	open_submenu(save_submenu)
