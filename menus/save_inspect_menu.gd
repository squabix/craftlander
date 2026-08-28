extends Menu
class_name SaveInspectMenu

signal deleted(slot: int)

@export_group("Info")
@export var created_label: Label
@export var saved_label: Label
@export var island_label: Label
@export var boat_level_label: Label
@export var islands_explored_label: Label

@export_group("Seed", "seed")
@export var seed_label: Label
@export var seed_button_copy: Button

@export_group("Deletion", "delete")
@export var delete_button: Button
@export var delete_row_confirm: Control
@export var delete_button_confirm: Button
@export var delete_button_cancel: Button

var current_seed_text := ""
var current_slot := -1


func _ready() -> void:
	super()
	seed_button_copy.pressed.connect(_on_copy_seed_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	delete_button_confirm.pressed.connect(_on_confirm_delete_pressed)
	delete_button_cancel.pressed.connect(_on_cancel_delete_pressed)


func show_save(slot: int) -> void:
	var save := Save.load_from_disk(Main.get_slot_path(slot)) as GameSave
	if save == null:
		return

	current_slot = slot
	delete_button.visible = true
	delete_row_confirm.visible = false

	created_label.text = "Created: %s" % SaveMenu.format_date(save.creation_datetime)
	saved_label.text = "Last Saved: %s" % SaveMenu.format_date(save.write_datetime)
	current_seed_text = str(save.base_seed)
	seed_label.text = "Seed: %s" % current_seed_text
	island_label.text = "Current Island: %s" % (save.current_level_index + 1)
	boat_level_label.text = "Boat Level: %s" % save.boat_level
	islands_explored_label.text = "Islands Explored: %s" % save.generated_levels.size()


func _on_copy_seed_pressed() -> void:
	DisplayServer.clipboard_set(current_seed_text)


func _on_delete_pressed() -> void:
	delete_button.visible = false
	delete_row_confirm.visible = true


func _on_cancel_delete_pressed() -> void:
	delete_row_confirm.visible = false
	delete_button.visible = true


func _on_confirm_delete_pressed() -> void:
	DirAccess.remove_absolute(Main.get_slot_path(current_slot))
	deleted.emit(current_slot)
