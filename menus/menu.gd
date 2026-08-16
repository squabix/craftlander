class_name Menu
extends Control

signal backed_out

static var _last_action_frame: int = -1

@export var do_auto_focus := true

@export_group("Visibility", "visibility")
@export var visibility_unchanging := false
@export var visibility_proxy: CanvasItem

@export_group("Back", "back")
@export var back_button: Button
@export var back_action: StringName = &"ui_cancel"

var active_submenu: Menu


static func is_frame_locked() -> bool:
	return Engine.get_process_frames() == _last_action_frame


static func lock_frame() -> bool:
	if is_frame_locked():
		return true
	_last_action_frame = Engine.get_process_frames()
	return false


func _ready() -> void:
	
	# Connect back button
	if back_button != null:
		back_button.pressed.connect(back)
	
	# Auto focus if visible on ready
	if visible:
		auto_focus()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
		
	# If a submenu is active, let the submenu process its own input
	if is_instance_valid(active_submenu) and active_submenu.is_visible_in_tree():
		return

	if not back_action.is_empty() and event.is_action_pressed(back_action):
		if Menu.is_frame_locked():
			return
		back()


func back() -> void:
	if Menu.lock_frame():
		return
	backed_out.emit()


func set_visibility(to: bool) -> void:
	if visibility_unchanging:
		return
	if visibility_proxy != null:
		visibility_proxy.visible = to
		return
	visible = to


func open_submenu(submenu: Menu) -> void:
	if Menu.lock_frame():
		return

	if is_instance_valid(active_submenu):
		active_submenu.set_visibility(false)
		active_submenu.close()
	set_visibility(false)
	set_submenu(submenu)
	active_submenu.open()
	active_submenu.set_visibility(true)
	submenu.auto_focus()


func open() -> void:
	pass


func close() -> void:
	pass


func close_submenu() -> void:
	if is_instance_valid(active_submenu):
		active_submenu.set_visibility(false)
		active_submenu.close()
	set_submenu(null)
	set_visibility(true)
	open()
	auto_focus()


func set_submenu(to: Menu) -> void:
	if is_instance_valid(active_submenu):
		if active_submenu.backed_out.is_connected(close_submenu):
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
