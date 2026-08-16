class_name VirtualCursor
extends CanvasLayer

const WARP_COOLDOWN_LENGTH := 0.15  # Buffer time to ignore synthetic warp events

signal showed_texture
signal hid_texture

@export var do_warp_mouse := true
@export var do_focus := true
@export var do_match_parent_visibility := true

@export_group("Motion")
@export_range(0.0, 0.9) var deadzone := 0.1
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var min_speed := 200.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var max_speed := 9000.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s²") var acceleration := 2500.0

@export_group("Texture", "texture")
@export var texture: Texture2D
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var texture_size := Vector2(32, 32)

@export_group("Input Actions", "action")
@export var action_up: StringName
@export var action_down: StringName
@export var action_left: StringName
@export var action_right: StringName

@export_group("Bounds", "bounds")
@export var bounds_enabled := true
@export var bounds_as_viewport := true

@export_subgroup("Custom Bounds", "bounds")
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var bounds_begin: Vector2
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var bounds_end: Vector2

var position: Vector2
var hovered_control: Control
var texture_rect: TextureRect
var texture_visible := false

var current_speed := 0.0
var warp_cooldown := 0.0

@onready var motion_actions: Array[StringName] = [action_left, action_right, action_up, action_down]


func _ready() -> void:
	position = get_viewport().get_mouse_position()

	if bounds_as_viewport:
		update_bounds_to_viewport()
		get_viewport().size_changed.connect(update_bounds_to_viewport)

	if texture != null:
		add_texture()
	
	if do_match_parent_visibility and parent_has_visibility():
		get_parent().visibility_changed.connect(match_parent_visibility)

func parent_has_visibility() -> bool:
	var parent := get_parent()
	return parent is CanvasItem or parent is CanvasLayer

func match_parent_visibility() -> void:
	if not parent_has_visibility():
		return
	visible = get_parent().visible


func _process(delta: float) -> void:
	if warp_cooldown > 0.0:
		warp_cooldown -= delta

	var input_dir := Input.get_vector(action_left, action_right, action_up, action_down)
	var input_length := input_dir.length()

	if input_length > deadzone:
		show_texture()

		# Accelerate scalar speed magnitude instead of 2D vector momentum
		current_speed = move_toward(current_speed, max_speed, acceleration * delta)
		if current_speed < min_speed:
			current_speed = min_speed

		# Direction turns instantly while magnitude scales up
		var move_dir := input_dir.normalized()
		position += move_dir * current_speed * delta
		clamp_position()
		warp_mouse()

		if is_instance_valid(texture_rect):
			texture_rect.global_position = position
	else:
		current_speed = 0.0

	if do_focus:
		var new_hovered_control = get_viewport().gui_get_hovered_control()
		if hovered_control != new_hovered_control:
			if is_instance_valid(new_hovered_control) and new_hovered_control.focus_mode != Control.FOCUS_NONE:
				hovered_control = new_hovered_control
				hovered_control.grab_focus()
			elif is_instance_valid(hovered_control):
				hovered_control.release_focus()
				hovered_control = null


func warp_mouse() -> void:
	if not do_warp_mouse:
		return
	get_viewport().warp_mouse(position)
	warp_cooldown = WARP_COOLDOWN_LENGTH


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if warp_cooldown > 0.0:
			return

		if not receiving_motion_input() and event.velocity.length() > 0.5:
			position = event.position
			hide_texture()


func add_texture() -> void:
	Util.safe_free(texture_rect)
	texture_rect = TextureRect.new()
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = texture
	texture_rect.custom_minimum_size = texture_size
	texture_rect.size = texture_size
	texture_rect.visible = false
	add_child(texture_rect)


func update_bounds_to_viewport() -> void:
	bounds_begin = Vector2.ZERO
	bounds_end = get_viewport().get_visible_rect().size


func show_texture() -> void:
	if texture_visible or not is_instance_valid(texture_rect):
		return
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	texture_rect.visible = true
	texture_visible = true
	showed_texture.emit()


func hide_texture() -> void:
	if not texture_visible or not is_instance_valid(texture_rect):
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	texture_rect.visible = false
	texture_visible = false
	hid_texture.emit()


func receiving_motion_input() -> bool:
	for action in motion_actions:
		if Input.is_action_pressed(action):
			return true
	return false


func clamp_position() -> void:
	if not bounds_enabled:
		return
	position = position.clamp(bounds_begin, bounds_end)
