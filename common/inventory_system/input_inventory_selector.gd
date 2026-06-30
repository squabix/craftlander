class_name InputInventorySelector
extends InventorySelector

@export_group("Number Keys")
@export var use_num_key_input := true
@export var num_key_index_map: Dictionary[Key, int] = {
	KEY_1: 0,
	KEY_2: 1,
	KEY_3: 2,
	KEY_4: 3,
	KEY_5: 4,
	KEY_6: 5,
	KEY_7: 6,
	KEY_8: 7,
	KEY_9: 8,
	KEY_0: 9,
}

@export_group("Scrolling")
@export var use_scrolling := true
@export var scroll_up_input_action := ""
@export var scroll_down_input_action := ""
@export var scroll_min_index := 0
@export var scroll_max_index := -1


func _process(_delta: float) -> void:
	heed_scroll_input()


func _input(event: InputEvent) -> void:
	if not is_num_key_press(event):
		return

	var index := num_key_index_map[event.keycode]
	if index >= inventory.size:
		return

	selected_index = index


func scroll(direction: int, skip_null: bool = false) -> void:
	if not enabled:
		return

	if inventory == null:
		return

	var old_index := selected_index
	selected_index = scroll_wrap(old_index + direction)

	if skip_null:
		# Every slot is null
		if inventory.is_empty():
			return

		# Scroll until reached non-null slot or wrapped back to initial slot
		while get_current_instance() == null and selected_index != old_index:
			scroll(direction, false)


func scroll_wrap(index: int) -> int:
	return wrapi(index, scroll_min_index, scroll_max_index + 1 if scroll_max_index != -1 else inventory.size)


func heed_scroll_input() -> void:
	if not enabled:
		return

	if not use_scrolling:
		return

	# Scroll input
	if Input.is_action_just_pressed(scroll_up_input_action):
		scroll(-1)
	if Input.is_action_just_pressed(scroll_down_input_action):
		scroll(1)


func is_num_key_press(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.is_echo() and num_key_index_map.has(event.keycode)
