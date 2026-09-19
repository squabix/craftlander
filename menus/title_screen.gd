class_name TitleScreen
extends Menu

@export_group("Submenus")
@export var save_submenu: SaveMenu
@export var settings_submenu: Menu
@export var about_submenu: Menu

@export_group("Main Buttons")
@export var new_game_button: Button
@export var load_game_button: Button
@export var settings_button: Button
@export var about_button: Button
@export var quit_button: Button

@onready var button_connections: Dictionary[Button, Callable] = {
	new_game_button: start_save_selection.bind(SaveMenu.SelectMode.NEW),
	load_game_button: start_save_selection.bind(SaveMenu.SelectMode.LOAD),
	settings_button: open_submenu.bind(settings_submenu),
	about_button: open_submenu.bind(about_submenu),
	quit_button: get_tree().quit,
}


func _ready() -> void:
	super()
	for button: Button in button_connections:
		button.pressed.connect(button_connections[button])


func start_save_selection(mode: SaveMenu.SelectMode) -> void:
	save_submenu.current_select_mode = mode
	open_submenu(save_submenu)
