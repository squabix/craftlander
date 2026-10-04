class_name Carousel
extends Control

signal page_changed(index: int, page: Control)

@export var wrap_enabled := false
@export var input_enabled := true

@export_group("Transitions", "transition")
@export var transition_trans := Tween.TRANS_CUBIC
@export var transition_ease := Tween.EASE_OUT
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var transition_duration := 0.3

@export_group("Navigation")
@export var previous_button: Button
@export var next_button: Button
@export var previous_action: StringName = &"ui_left"
@export var next_action: StringName = &"ui_right"

@export_group("Dots", "dot")
@export var dot_container: Container
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var dot_size := Vector2(12.0, 12.0)
@export var dot_active_style: StyleBox
@export var dot_inactive_style: StyleBox

var current_index := 0
var scroll := 0.0:
	set(to):
		scroll = to
		layout_pages()

var _tween: Tween


func _ready() -> void:
	resized.connect(layout_pages)
	if is_instance_valid(previous_button):
		previous_button.pressed.connect(previous)
	if is_instance_valid(next_button):
		next_button.pressed.connect(next)
	refresh()


func _input(event: InputEvent) -> void:
	if not input_enabled or not is_visible_in_tree():
		return

	if event.is_action_pressed(previous_action):
		previous()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(next_action):
		next()
		get_viewport().set_input_as_handled()


func get_pages() -> Array[Control]:
	var pages: Array[Control]
	for child in get_children():
		if child is Control:
			pages.append(child)
	return pages


func get_page_count() -> int:
	return get_pages().size()


func get_current_page() -> Control:
	var pages := get_pages()
	if current_index >= pages.size():
		return null
	return pages[current_index]


func refresh() -> void:
	current_index = clampi(current_index, 0, maxi(get_page_count() - 1, 0))
	scroll = current_index
	rebuild_dots()
	update_navigation()


func select_page(index: int, animate := true) -> void:
	var count := get_page_count()
	if count == 0:
		return

	var changed := clampi(index, 0, count - 1) != current_index
	current_index = clampi(index, 0, count - 1)
	move_to_current(animate)

	if not changed:
		return
	update_dots()
	update_navigation()
	page_changed.emit(current_index, get_current_page())


func next() -> void:
	step(1)


func previous() -> void:
	step(-1)


func step(direction: int) -> void:
	var count := get_page_count()
	if count == 0:
		return

	var target := current_index + direction
	if wrap_enabled:
		target = posmod(target, count)
	select_page(target)


func move_to_current(animate: bool) -> void:
	if is_instance_valid(_tween):
		_tween.kill()

	if not animate or not is_inside_tree():
		scroll = current_index
		return

	_tween = create_tween().set_trans(transition_trans).set_ease(transition_ease)
	_tween.tween_property(self, "scroll", float(current_index), transition_duration)


func layout_pages() -> void:
	var pages := get_pages()
	for i in pages.size():
		pages[i].position = Vector2((i - scroll) * size.x, 0.0)
		pages[i].size = size


func rebuild_dots() -> void:
	if not is_instance_valid(dot_container):
		return

	for dot in dot_container.get_children():
		dot_container.remove_child(dot)
		dot.queue_free()

	for i in get_page_count():
		var dot := Panel.new()
		dot.custom_minimum_size = dot_size
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot_container.add_child(dot)

	update_dots()


func update_dots() -> void:
	if not is_instance_valid(dot_container):
		return

	var dots := dot_container.get_children()
	for i in dots.size():
		var style := dot_active_style if i == current_index else dot_inactive_style
		dots[i].add_theme_stylebox_override(&"panel", style)


func update_navigation() -> void:
	var count := get_page_count()
	if is_instance_valid(previous_button):
		previous_button.disabled = count < 2 or (not wrap_enabled and current_index == 0)
	if is_instance_valid(next_button):
		next_button.disabled = count < 2 or (not wrap_enabled and current_index == count - 1)
