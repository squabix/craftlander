extends Object
class_name MouseModeController

static func show() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

static func hide() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

static func capture() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

static func confine() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	
static func confine_hidden() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN

static func is_visible() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_VISIBLE

static func is_hidden() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_HIDDEN

static func is_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_VISIBLE

static func is_confined() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED

static func is_confined_hidden() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CONFINED_HIDDEN

static func toggle(a: Input.MouseMode, b: Input.MouseMode) -> void:
	if Input.mouse_mode != a:
		Input.mouse_mode = a
	else:
		Input.mouse_mode = b
