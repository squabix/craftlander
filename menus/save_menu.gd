extends Menu
class_name SaveMenu

signal started_new_game(save: int)
signal loaded_game(save: int)

enum SelectMode {NONE, NEW, LOAD}

@export var save_buttons: Array[Button]

var current_select_mode := SelectMode.NONE

func _ready() -> void:
	super()
	for i in len(save_buttons):
		save_buttons[i].pressed.connect(select_save.bind(i))

func select_save(index: int) -> void:
	match current_select_mode:
		SelectMode.NEW:
			started_new_game.emit(index)
		SelectMode.LOAD:
			loaded_game.emit(index)
