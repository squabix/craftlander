extends Menu
class_name TitleScreen

# Submenus
@onready var main_submenu: Container = $MainButtonContainer
@onready var save_submenu: SaveMenu = $SaveMenu
@onready var settings_submenu: Menu = $SettingsMenu
@onready var all_submenus: Array[Control] = [
	main_submenu,
	save_submenu,
	settings_submenu
]

# Main buttons
@onready var new_game_button: Button = $MainButtonContainer/NewGameButton
@onready var settings_button: Button = $MainButtonContainer/SettingsButton
@onready var quit_button: Button = $MainButtonContainer/QuitButton

func _ready() -> void:
	super()
	new_game_button.pressed.connect(start_new_save_selection)
	settings_button.pressed.connect(open_submenu.bind(settings_submenu))
	quit_button.pressed.connect(get_tree().quit)

func start_new_save_selection():
	save_submenu.current_select_mode = save_submenu.SelectMode.NEW
	open_submenu(save_submenu)
