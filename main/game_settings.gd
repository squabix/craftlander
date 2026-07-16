extends Node

const SAVE_PATH := "user://settings.cfg"
var config := ConfigFile.new()


func _ready() -> void:
	load_settings()

func save_settings() -> void:
	config.save(SAVE_PATH)

func load_settings() -> void:
	var err = config.load(SAVE_PATH)
	if err != OK: return

	apply_video_settings()
	apply_audio_settings()

func set_volume(bus_name: StringName, value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	config.set_value("audio", bus_name, value)
	save_settings()

func apply_audio_settings() -> void:
	for bus in ["Master", "Music", "SFX"]:
		var vol = config.get_value("audio", bus, 1.0)
		set_volume(bus, vol)

func set_vsync(enabled: bool) -> void:
	var mode = DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)
	config.set_value("video", "vsync", enabled)
	save_settings()

func set_msaa(index: int) -> void:
	get_viewport().msaa_3d = index as Viewport.MSAA
	config.set_value("video", "msaa", index)
	save_settings()

func apply_video_settings() -> void:
	var mode = config.get_value("video", "mode", DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_mode(mode)
	set_vsync(config.get_value("video", "vsync", true))
	set_msaa(config.get_value("video", "msaa", 1))
