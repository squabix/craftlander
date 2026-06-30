class_name PopupDisplay
extends Control

signal pressed_button(index: int)

static var identification := Identification.new()

@export var title_label: Label
@export var body_label: Label
@export var id := 0
@export var handle_mouse_mode := true
@export var continue_action := "ui_accept"

var buttons: Array[Node]


static func display(body: String, title: String = "", display_id: int = 0) -> PopupDisplay:
	var popup_display: PopupDisplay = identification.fetch(display_id)

	if not is_instance_valid(popup_display):
		printerr("Invalid display")
		return null

	popup_display.process_mode = Node.PROCESS_MODE_ALWAYS
	popup_display.show()

	var old_mouse_mode := Input.mouse_mode
	if popup_display.handle_mouse_mode:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	popup_display.get_tree().paused = true
	popup_display.set_labels(body, title)

	popup_display.pressed_button.connect(
		func(_index: int):
			popup_display.get_tree().paused = false
			popup_display.hide()
			if popup_display.handle_mouse_mode:
				Input.mouse_mode = old_mouse_mode
	)
	return popup_display


func _ready() -> void:
	identification.auto_register(self)
	hide()
	buttons = Util.find_children_of_class(self, "Button")
	for i in buttons.size():
		buttons[i].pressed.connect(
			func():
				pressed_button.emit(i)
		)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(continue_action):
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
