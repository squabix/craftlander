class_name ActionHint
extends HBoxContainer

@export var action: StringName = &"":
	set(to):
		action = to
		if is_inside_tree():
			_controller_icon.path = action

@export var hint_text := "":
	set(to):
		hint_text = to
		if is_inside_tree():
			label.text = hint_text

@export_custom(PROPERTY_HINT_NONE, "suffix:px") var icon_size := 24:
	set(to):
		icon_size = to
		if is_inside_tree():
			icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)

@export var icon_rect: TextureRect
@export var label: Label

var _controller_icon := ControllerIconTexture.new()


func _ready() -> void:
	icon_rect.texture = _controller_icon
	icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
	_controller_icon.path = action
	label.text = hint_text
