extends Menu
class_name SaveMenu

const SAVED_TEXT_FORMAT := "SAVE %s"
const UNSAVED_TEXT := "EMPTY"
const UNSAVED_ALPHA := 0.75

signal started_new_game(save: int)
signal loaded_game(save: int)

enum SelectMode {NONE, NEW, LOAD}

@export var save_buttons: Array[Button]

var current_select_mode := SelectMode.NONE

func _ready() -> void:
	super()
	for slot in len(save_buttons):
		save_buttons[slot].pressed.connect(select_save.bind(slot))
	update_button_visuals()


func update_button_visuals() -> void:
	for slot in len(save_buttons):
		var button := save_buttons[slot]
		var is_saved := Main.is_saved(slot)
		button.text = SAVED_TEXT_FORMAT % (slot + 1) if is_saved else UNSAVED_TEXT
		button.modulate.a = 1.0 if is_saved else UNSAVED_ALPHA

func select_save(slot: int) -> void:
	match current_select_mode:
		SelectMode.NEW:
			started_new_game.emit(slot)
		SelectMode.LOAD:
			if not Main.is_saved(slot):
				return
			loaded_game.emit(slot)
