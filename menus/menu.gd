class_name Menu
extends Control

signal backed_out

@export var visibility_proxy: CanvasItem
@export var do_auto_focus := true

@export_group("Back", "back")
@export var back_button: Button
@export var back_action: StringName = &"ui_cancel"

var active_submenu: Menu


func _ready() -> void:
	if back_button != null:
		back_button.pressed.connect(back)
	if visible:
		auto_focus()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(back_action) and active_submenu == null:
		back()


func back() -> void:
	backed_out.emit()


func set_visibility(to: bool) -> void:
	if visibility_proxy != null:
		visibility_proxy.visible = to
		return
	visible = to


func open_submenu(submenu: Menu) -> void:
	set_visibility(false)
	set_submenu(submenu)
	active_submenu.set_visibility(true)
	submenu.auto_focus()


func close_submenu() -> void:
	active_submenu.set_visibility(false)
	set_submenu(null)
	set_visibility(true)
	auto_focus()


func set_submenu(to: Menu) -> void:
	if active_submenu != null:
		active_submenu.backed_out.disconnect(close_submenu)

	active_submenu = to

	if active_submenu == null:
		return

	active_submenu.backed_out.connect(close_submenu)


func auto_focus() -> void:
	var control := find_next_valid_focus()
	if not is_instance_valid(control):
		return
	control.grab_focus()
