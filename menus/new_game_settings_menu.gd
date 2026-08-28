extends Menu
class_name NewGameSettingsMenu

signal confirmed(slot: int, seed_value: int)

@export var slot_label: Label
@export var start_button: Button
@export var seed_field: LineEdit
@export var overwrite_warning: Control

var target_slot := -1


func _ready() -> void:
	super()
	start_button.pressed.connect(_on_start_pressed)


func open_for_slot(slot: int) -> void:
	target_slot = slot
	seed_field.text = ""
	slot_label.text = "NEW GAME - SLOT %s" % (slot + 1)
	overwrite_warning.visible = Main.is_saved(slot)


func _on_start_pressed() -> void:
	confirmed.emit(target_slot, resolve_seed(seed_field.text))


static func resolve_seed(raw_text: String) -> int:
	var trimmed := raw_text.strip_edges()
	if trimmed.is_empty():
		return randi()
	if trimmed.is_valid_int():
		return trimmed.to_int()
	return trimmed.hash()
