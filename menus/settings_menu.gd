class_name SettingsMenu
extends Menu

@export var music_slider: Slider
@export var sfx_slider: Slider
@export var vsync_toggle: Button
@export var full_screen_toggle: Button
@export var aa_option: OptionButton
@export var invert_y_toggle: Button

@export_group("Difficulty", "difficulty")
@export var difficulty_row: Control
@export var difficulty_slider: Slider
@export var difficulty_name_label: Label


func _ready() -> void:
	super()
	var named_range := Difficulty.get_named_range()
	difficulty_slider.min_value = named_range.x
	difficulty_slider.max_value = named_range.y
	sync_ui_with_settings()


func sync_ui_with_settings() -> void:
	# Audio
	#music_slider.value = GameSettings.config.get_value("audio", "Music", 0.8)
	#sfx_slider.value = GameSettings.config.get_value("audio", "SFX", 0.8)

	# Video
	vsync_toggle.button_pressed = GameSettings.config.get_value("video", "vsync", true)
	full_screen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	aa_option.selected = GameSettings.config.get_value("video", "msaa", 1)

	# Gameplay
	invert_y_toggle.button_pressed = GameSettings.config.get_value("gameplay", "invert_y", false)

	difficulty_row.visible = is_in_game()
	if is_in_game():
		difficulty_slider.value = Main.loaded_save.difficulty
		update_difficulty_label()


func _on_full_screen_toggled(toggled_on: bool) -> void:
	var mode = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	GameSettings.config.set_value("video", "mode", mode)
	GameSettings.save_settings()


func _on_vsync_toggled(toggled_on: bool) -> void:
	GameSettings.set_vsync(toggled_on)


func _on_anti_aliasing_selected(index: int) -> void:
	# index: 0=Disabled, 1=2x, 2=4x, 3=8x
	GameSettings.set_msaa(index)


func _on_shadow_quality_selected(index: int) -> void:
	var shadow_size = [1024, 2048, 4096, 8192]
	RenderingServer.directional_shadow_atlas_set_size(shadow_size[index], true)
	GameSettings.config.set_value("video", "shadow_quality", index)
	GameSettings.save_settings()


func _on_invert_y_toggled(toggled_on: bool) -> void:
	GameSettings.config.set_value("gameplay", "invert_y", toggled_on)
	GameSettings.save_settings()


func is_in_game() -> bool:
	return is_instance_valid(Main.root) and is_instance_valid(Main.root.level)


func update_difficulty_label() -> void:
	difficulty_name_label.text = Difficulty.get_display_name(int(difficulty_slider.value))


func _on_difficulty_changed(value: float) -> void:
	update_difficulty_label()
	if not is_in_game():
		return
	Main.root.set_difficulty(int(value))


func _on_music_volume_changed(value: float) -> void:
	GameSettings.set_volume("Music", value)


func _on_sfx_volume_changed(value: float) -> void:
	GameSettings.set_volume("SFX", value)
