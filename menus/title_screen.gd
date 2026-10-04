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

@export_group("Feedback", "feedback")
@export var feedback_button: Button
@export var feedback_url := "https://forms.gle/q4MtDTKMZBqj6Xrb7"

@onready var button_connections: Dictionary[Button, Callable] = {
	new_game_button: start_save_selection.bind(SaveMenu.SelectMode.NEW),
	load_game_button: start_save_selection.bind(SaveMenu.SelectMode.LOAD),
	settings_button: open_submenu.bind(settings_submenu),
	about_button: open_submenu.bind(about_submenu),
	quit_button: Main.quit_game,
	feedback_button: open_feedback_form,
}


func _ready() -> void:
	super()
	for button: Button in button_connections:
		button.pressed.connect(button_connections[button])


func set_visibility(to: bool) -> void:
	super(to)
	feedback_button.visible = to


func start_save_selection(mode: SaveMenu.SelectMode) -> void:
	save_submenu.current_select_mode = mode
	open_submenu(save_submenu)


func open_feedback_form() -> void:
	if feedback_url.is_empty():
		push_warning("TitleScreen: feedback_url is not set")
		return
	OS.shell_open(feedback_url)
