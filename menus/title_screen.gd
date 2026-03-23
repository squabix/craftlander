extends Control
class_name TitleScreen

enum SaveSelectMode {NONE, NEW, LOAD}

const BACK_BUTTON_NAME := "BackButton"

signal started_new_game(save: int)
signal loaded_game(save: int)

signal back_button_pressed

var current_save_select_mode: SaveSelectMode

# Button containers
@onready var main_button_container: Container = $MainButtonContainer
@onready var save_button_container: Container = $SaveButtonContainer
@onready var all_button_containers: Array[Container] = [
	main_button_container,
	save_button_container
]

# Main buttons
@onready var new_game_button: Button = $MainButtonContainer/NewGameButton
@onready var quit_game_button: Button = $MainButtonContainer/QuitButton

# Save buttons
@onready var save_buttons: Array[Button]

func _ready() -> void:
	
	# Load save buttons
	for child in save_button_container.get_children():
		if child is Button:
			if child.name == BACK_BUTTON_NAME:
				child.pressed.connect(reset_to_main)
				continue
			save_buttons.append(child)
			child.pressed.connect(select_save.bind(save_buttons.find(child))) # Select save when pressed
	
	reset_to_main()
	
	new_game_button.pressed.connect(start_save_selection.bind(SaveSelectMode.NEW))
	quit_game_button.pressed.connect(get_tree().quit)

func reset_to_main() -> void:
	for container in all_button_containers:
		container.hide()
	main_button_container.show()
	

func select_save(save: int) -> void:
	match current_save_select_mode:
		SaveSelectMode.NEW:
			started_new_game.emit(save)
		SaveSelectMode.LOAD:
			loaded_game.emit(save)

func start_save_selection(mode: SaveSelectMode):
	current_save_select_mode = mode
	main_button_container.hide()
	save_button_container.show()
