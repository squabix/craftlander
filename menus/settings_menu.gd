extends Menu
class_name SettingsMenu

func _ready() -> void:
	sync_ui_with_settings()

func sync_ui_with_settings() -> void:
	# Audio
	%MusicSlider.value = GameSettings.config.get_value("audio", "Music", 0.8)
	%SFXSlider.value = GameSettings.config.get_value("audio", "SFX", 0.8)
	
	# Video
	%VSyncToggle.button_pressed = GameSettings.config.get_value("video", "vsync", true)
	%FullScreenToggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	%AAOption.selected = GameSettings.config.get_value("video", "msaa", 1)
	
	# Gameplay
	%InvertYToggle.button_pressed = GameSettings.config.get_value("gameplay", "invert_y", false)

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

func _on_music_volume_changed(value: float) -> void:
	GameSettings.set_volume("Music", value)

func _on_sfx_volume_changed(value: float) -> void:
	GameSettings.set_volume("SFX", value)


func _on_back_button_pressed() -> void:
	back()
