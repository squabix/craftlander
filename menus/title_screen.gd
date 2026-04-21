extends Control
class_name TitleScreen

enum SaveSelectMode {NONE, NEW, LOAD}

const BACK_BUTTON_NAME := "BackButton"

signal started_new_game(save: int)
signal loaded_game(save: int)

signal back_button_pressed

var current_save_select_mode: SaveSelectMode

# Submenus
@onready var main_submenu: Container = $MainButtonContainer
@onready var save_submenu: Container = $SaveButtonContainer
@onready var settings_submenu: Menu = $SettingsMenu
@onready var all_submenus: Array[Control] = [
	main_submenu,
	save_submenu,
	settings_submenu
]

# Main buttons
@onready var new_game_button: Button = $MainButtonContainer/NewGameButton
@onready var quit_game_button: Button = $MainButtonContainer/QuitButton
@onready var settings_button: Button = $MainButtonContainer/SettingsButton

# Save buttons
@onready var save_buttons: Array[Button]

func _ready() -> void:
	
	# Load save buttons
	for child in save_submenu.get_children():
		if child is Button:
			if child.name == BACK_BUTTON_NAME:
				child.pressed.connect(reset_to_main)
				continue
			save_buttons.append(child)
			child.pressed.connect(select_save.bind(save_buttons.find(child))) # Select save when pressed
	
	reset_to_main()
	
	new_game_button.pressed.connect(start_save_selection.bind(SaveSelectMode.NEW))
	settings_button.pressed.connect(open_settings_menu)
	quit_game_button.pressed.connect(get_tree().quit)
	

func reset_to_main() -> void:
	for container in all_submenus:
		container.hide()
	main_submenu.show()

func open_settings_menu() -> void:
	main_submenu.hide()
	settings_submenu.show()
	await settings_submenu.backed_out
	reset_to_main()

func select_save(save: int) -> void:
	match current_save_select_mode:
		SaveSelectMode.NEW:
			started_new_game.emit(save)
		SaveSelectMode.LOAD:
			loaded_game.emit(save)

func start_save_selection(mode: SaveSelectMode):
	current_save_select_mode = mode
	main_submenu.hide()
	save_submenu.show()
