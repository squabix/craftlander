class_name HintToast
extends Control

const FADE_SPEED := 0.1
const HOLD_DURATION := 6.0

static var identification: Identification = Identification.new()

@export var id: int
@export var label: Label
@export var icon: TextureRect
@export var visible_when_paused: bool

var _queue: Array[Dictionary] = []
var _showing := false
var _hold_time_left := 0.0


static func display(text: String, icon_action: StringName = &"", display_id: int = 0) -> void:
	if text.is_empty():
		return
	var toast: HintToast = identification.fetch(display_id)
	if not is_instance_valid(toast):
		return
	toast._queue.append({"text": text, "icon_action": icon_action})


func _ready() -> void:
	identification.auto_register(self)
	modulate.a = 0.0


func _process(delta: float) -> void:
	if not visible_when_paused and get_tree().paused:
		hide()
		return
	show()

	if _showing:
		modulate.a = move_toward(modulate.a, 1.0, FADE_SPEED)
		_hold_time_left -= delta
		if _hold_time_left <= 0.0:
			_showing = false
	elif not _queue.is_empty() and modulate.a <= 0.0:
		_show_next()
	else:
		modulate.a = move_toward(modulate.a, 0.0, FADE_SPEED)


func _show_next() -> void:
	var next: Dictionary = _queue.pop_front()
	if is_instance_valid(label):
		label.text = next.get("text", "")
	_set_icon(next.get("icon_action", &""))
	_hold_time_left = HOLD_DURATION
	_showing = true


func _set_icon(action: StringName) -> void:
	if not is_instance_valid(icon):
		return
	if action.is_empty():
		icon.hide()
		return
	icon.show()
	var icon_texture := ControllerIconTexture.new()
	icon_texture.path = action
	icon.texture = icon_texture
