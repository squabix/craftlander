class_name SettingsMenu
extends Menu

const WINDOW_MODES: Array[DisplayServer.WindowMode] = [
	DisplayServer.WINDOW_MODE_WINDOWED,
	DisplayServer.WINDOW_MODE_FULLSCREEN,
	DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
]

@export var music_slider: Slider
@export var sfx_slider: Slider
@export var vsync_toggle: Button
@export var window_mode_option: OptionButton
@export var aa_option: OptionButton
@export var shadow_option: OptionButton
@export var ssao_toggle: Button
@export var glow_toggle: Button
@export var max_fps_option: OptionButton
@export var resolution_scale_slider: Slider
@export var invert_y_toggle: Button
@export var tutorial_hints_toggle: Button
@export var screen_shake_toggle: Button
@export var vignette_toggle: Button
@export var screen_effects_toggle: Button
@export var look_sensitivity_slider: Slider
@export var fov_slider: Slider

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
	window_mode_option.selected = max(WINDOW_MODES.find(DisplayServer.window_get_mode()), 0)
	aa_option.selected = GameSettings.config.get_value("video", "msaa", 1)
	shadow_option.selected = GameSettings.config.get_value("video", "shadow_quality", 1)
	ssao_toggle.button_pressed = GameSettings.config.get_value("video", "ssao_enabled", true)
	glow_toggle.button_pressed = GameSettings.config.get_value("video", "glow_enabled", true)
	max_fps_option.selected = max(GameSettings.FPS_CAPS.find(GameSettings.config.get_value("video", "max_fps", 0)), 0)
	resolution_scale_slider.value = GameSettings.config.get_value("video", "resolution_scale", 1.0)

	# Gameplay
	invert_y_toggle.button_pressed = GameSettings.config.get_value("gameplay", "invert_y", false)
	tutorial_hints_toggle.button_pressed = GameSettings.config.get_value("gameplay", "tutorial_hints_enabled", true)
	screen_shake_toggle.button_pressed = GameSettings.config.get_value("gameplay", "screen_shake_enabled", true)
	vignette_toggle.button_pressed = GameSettings.config.get_value("gameplay", "vignette_enabled", true)
	screen_effects_toggle.button_pressed = GameSettings.config.get_value("gameplay", "hurt_effect_enabled", true)
	look_sensitivity_slider.value = GameSettings.config.get_value("gameplay", "look_sensitivity", look_sensitivity_slider.value)
	fov_slider.value = GameSettings.config.get_value("gameplay", "fov", fov_slider.value)

	difficulty_row.visible = is_in_game()
	if is_in_game():
		difficulty_slider.value = Main.loaded_save.difficulty
		update_difficulty_label()


func _on_window_mode_selected(index: int) -> void:
	GameSettings.set_window_mode(WINDOW_MODES[index])


func _on_vsync_toggled(toggled_on: bool) -> void:
	GameSettings.set_vsync(toggled_on)


func _on_anti_aliasing_selected(index: int) -> void:
	# index: 0=Disabled, 1=2x, 2=4x, 3=8x
	GameSettings.set_msaa(index)


func _on_shadow_quality_selected(index: int) -> void:
	GameSettings.set_shadow_quality(index)


func _on_ssao_toggled(toggled_on: bool) -> void:
	GameSettings.set_ssao_enabled(toggled_on)


func _on_glow_toggled(toggled_on: bool) -> void:
	GameSettings.set_glow_enabled(toggled_on)


func _on_max_fps_selected(index: int) -> void:
	# index: 0=Unlimited, 1=30, 2=60, 3=120, 4=144
	GameSettings.set_max_fps(GameSettings.FPS_CAPS[index])


func _on_resolution_scale_changed(value: float) -> void:
	GameSettings.set_resolution_scale(value)


func _on_invert_y_toggled(toggled_on: bool) -> void:
	GameSettings.config.set_value("gameplay", "invert_y", toggled_on)
	GameSettings.save_settings()


func _on_tutorial_hints_toggled(toggled_on: bool) -> void:
	GameSettings.config.set_value("gameplay", "tutorial_hints_enabled", toggled_on)
	GameSettings.save_settings()


func _on_look_sensitivity_changed(value: float) -> void:
	GameSettings.set_value("gameplay", "look_sensitivity", value)


func _on_fov_changed(value: float) -> void:
	GameSettings.set_value("gameplay", "fov", value)
	var player := get_player()
	if player != null:
		player.camera.fov = value


func _on_screen_shake_toggled(toggled_on: bool) -> void:
	GameSettings.config.set_value("gameplay", "screen_shake_enabled", toggled_on)
	GameSettings.save_settings()


func _on_vignette_toggled(toggled_on: bool) -> void:
	GameSettings.config.set_value("gameplay", "vignette_enabled", toggled_on)
	GameSettings.save_settings()
	var player := get_player()
	if player != null:
		player.vignette.visible = toggled_on


func _on_screen_effects_toggled(toggled_on: bool) -> void:
	GameSettings.config.set_value("gameplay", "hurt_effect_enabled", toggled_on)
	GameSettings.save_settings()
	var player := get_player()
	if player != null:
		player.hurt_effect_trigger.disabled = not toggled_on


func get_player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


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
