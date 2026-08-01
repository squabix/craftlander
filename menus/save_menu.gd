extends Menu
class_name SaveMenu

const SAVED_TEXT_FORMAT := "SAVE %s - %s"
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
		
		if Main.is_saved(slot):
			var slot_number := slot + 1
			var datetime_string := Time.get_datetime_string_from_datetime_dict(Save.load_from_disk(Main.get_slot_path(slot)).write_datetime, false).split("T")[0]
			button.text = SAVED_TEXT_FORMAT % [slot_number, datetime_string]
			button.modulate.a = 1.0
		else:
			button.text = UNSAVED_TEXT
			button.modulate.a = UNSAVED_ALPHA

func select_save(slot: int) -> void:
	match current_select_mode:
		SelectMode.NEW:
			started_new_game.emit(slot)
		SelectMode.LOAD:
			if not Main.is_saved(slot):
				return
			loaded_game.emit(slot)
