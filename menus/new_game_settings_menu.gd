extends Menu
class_name NewGameSettingsMenu

signal confirmed(slot: int, seed_value: int, difficulty: int)

@export var slot_label: Label
@export var start_button: Button
@export var seed_field: LineEdit
@export var overwrite_warning: Control
@export var difficulty_slider: Slider
@export var difficulty_name_label: Label

var target_slot := -1


func _ready() -> void:
	super()
	start_button.pressed.connect(_on_start_pressed)

	var named_range := Difficulty.get_named_range()
	difficulty_slider.min_value = named_range.x
	difficulty_slider.max_value = named_range.y
	difficulty_slider.value = Difficulty.SETTINGS.default_value
	update_difficulty_label()


func open_for_slot(slot: int) -> void:
	target_slot = slot
	seed_field.text = ""
	slot_label.text = "NEW GAME - SLOT %s" % (slot + 1)
	overwrite_warning.visible = Main.is_saved(slot)
	difficulty_slider.value = Difficulty.SETTINGS.default_value


func update_difficulty_label() -> void:
	difficulty_name_label.text = Difficulty.get_display_name(int(difficulty_slider.value))


func _on_difficulty_changed(_value: float) -> void:
	update_difficulty_label()


func _on_start_pressed() -> void:
	confirmed.emit(target_slot, resolve_seed(seed_field.text), int(difficulty_slider.value))


static func resolve_seed(raw_text: String) -> int:
	var trimmed := raw_text.strip_edges()
	if trimmed.is_empty():
		return randi()
	if trimmed.is_valid_int():
		return trimmed.to_int()
	return trimmed.hash()
