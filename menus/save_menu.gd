extends Menu
class_name SaveMenu

const SAVED_TEXT_FORMAT := "SAVE %s - %s"
const UNSAVED_TEXT := "EMPTY"
const UNSAVED_ALPHA := 0.75

signal started_new_game(save: int, seed_value: int)
signal loaded_game(save: int)

enum SelectMode {NONE, NEW, LOAD}

@export var save_buttons: Array[Button]
@export var inspect_buttons: Array[Button]
@export var inspect_submenu: SaveInspectMenu
@export var new_game_settings_submenu: NewGameSettingsMenu

var current_select_mode := SelectMode.NONE

func _ready() -> void:
	super()
	for slot in len(save_buttons):
		save_buttons[slot].pressed.connect(select_save.bind(slot))
		inspect_buttons[slot].pressed.connect(open_inspect.bind(slot))
	new_game_settings_submenu.confirmed.connect(_on_new_game_confirmed)
	inspect_submenu.deleted.connect(_on_save_deleted)
	update_button_visuals()


static func format_date(datetime_dict: Dictionary) -> String:
	return Time.get_datetime_string_from_datetime_dict(datetime_dict, false).split("T")[0]


func update_button_visuals() -> void:
	for slot in len(save_buttons):
		var button := save_buttons[slot]
		var is_saved := Main.is_saved(slot)

		if is_saved:
			var slot_number := slot + 1
			var datetime_string := format_date(Save.load_from_disk(Main.get_slot_path(slot)).write_datetime)
			button.text = SAVED_TEXT_FORMAT % [slot_number, datetime_string]
			button.modulate.a = 1.0
		else:
			button.text = UNSAVED_TEXT
			button.modulate.a = UNSAVED_ALPHA

		inspect_buttons[slot].disabled = not is_saved

func select_save(slot: int) -> void:
	match current_select_mode:
		SelectMode.NEW:
			new_game_settings_submenu.open_for_slot(slot)
			open_submenu(new_game_settings_submenu)
		SelectMode.LOAD:
			if not Main.is_saved(slot):
				return
			loaded_game.emit(slot)


func open_inspect(slot: int) -> void:
	if not Main.is_saved(slot):
		return
	inspect_submenu.show_save(slot)
	open_submenu(inspect_submenu)


func _on_new_game_confirmed(slot: int, seed_value: int) -> void:
	started_new_game.emit(slot, seed_value)


func _on_save_deleted(_slot: int) -> void:
	update_button_visuals()
	close_submenu()
