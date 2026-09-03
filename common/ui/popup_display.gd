class_name PopupDisplay
extends Control

signal pressed_button(index: int)

static var identification := Identification.new()
static var any_visible := false

@export var title_label: Label
@export var body_label: Label
@export var continue_icon_rect: TextureRect
@export var id := 0
@export var handle_mouse_mode := true
@export var continue_actions: Array[StringName] = [&"ui_accept", &"ui_cancel"]

var buttons: Array[Node]
var _was_already_paused := false
var _restore_mouse_mode := Input.MOUSE_MODE_VISIBLE


static func display(body: String, title: String = "", display_id: int = 0) -> PopupDisplay:
	var popup_display: PopupDisplay = identification.fetch(display_id)

	if not is_instance_valid(popup_display):
		push_error("Invalid display")
		return null

	popup_display.process_mode = Node.PROCESS_MODE_ALWAYS
	popup_display.show()
	any_visible = true

	popup_display._restore_mouse_mode = Input.mouse_mode
	if popup_display.handle_mouse_mode:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Track whether the tree was already paused
	popup_display._was_already_paused = popup_display.get_tree().paused
	popup_display.get_tree().paused = true
	popup_display.set_labels(body, title)

	if popup_display.pressed_button.is_connected(popup_display._on_pressed_button):
		popup_display.pressed_button.disconnect(popup_display._on_pressed_button)
	popup_display.pressed_button.connect(popup_display._on_pressed_button, CONNECT_ONE_SHOT)
	return popup_display


func _on_pressed_button(_index: int) -> void:
	any_visible = false
	if not _was_already_paused:
		get_tree().paused = false
	hide()
	if handle_mouse_mode:
		Input.mouse_mode = _restore_mouse_mode


func _ready() -> void:
	identification.auto_register(self)
	hide()
	buttons = Util.find_children_of_class(self, &"Button")
	for i in buttons.size():
		buttons[i].pressed.connect(
			func():
				pressed_button.emit(i)
		)

	if is_instance_valid(continue_icon_rect) and continue_actions.size() > 0:
		var icon_texture := ControllerIconTexture.new()
		icon_texture.path = continue_actions[0]
		continue_icon_rect.texture = icon_texture


func _process(_delta: float) -> void:
	if not visible:
		return
	for action in continue_actions:
		if Input.is_action_just_pressed(action):
			pressed_button.emit(0)


func set_labels(body: String, title: String) -> void:
	if title_label:
		if title.is_empty():
			title_label.hide()
		else:
			title_label.show()
			title_label.text = title
	if body_label:
		body_label.text = body
