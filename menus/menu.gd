extends Control
class_name Menu

signal backed_out

@export var back_button: Button
@export var back_input_action: StringName = "ui_cancel"
@export var visibility_proxy: CanvasItem

var active_submenu: Menu

func _ready() -> void:
	if back_button != null:
		back_button.pressed.connect(back)

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

func close_submenu() -> void:
	active_submenu.set_visibility(false)
	set_submenu(null)
	set_visibility(true)

func set_submenu(to: Menu) -> void:
	if active_submenu != null:
		active_submenu.backed_out.disconnect(close_submenu)
	
	active_submenu = to
	
	if active_submenu == null:
		return
	
	active_submenu.backed_out.connect(close_submenu)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(back_input_action) and active_submenu == null:
		back()
