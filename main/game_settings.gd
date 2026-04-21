extends Node

const SAVE_PATH = "user://settings.cfg"
var config = ConfigFile.new()


func _ready():
	load_settings()

func save_settings():
	config.save(SAVE_PATH)

func load_settings():
	var err = config.load(SAVE_PATH)
	if err != OK: return

	apply_video_settings()
	apply_audio_settings()

func set_volume(bus_name: String, value: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	config.set_value("audio", bus_name, value)
	save_settings()

func apply_audio_settings():
	for bus in ["Master", "Music", "SFX"]:
		var vol = config.get_value("audio", bus, 1.0)
		set_volume(bus, vol)

func set_vsync(enabled: bool):
	var mode = DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)
	config.set_value("video", "vsync", enabled)
	save_settings()

func set_msaa(index: int):
	get_viewport().msaa_3d = index as Viewport.MSAA
	config.set_value("video", "msaa", index)
	save_settings()

func apply_video_settings():
	var mode = config.get_value("video", "mode", DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_mode(mode)
	set_vsync(config.get_value("video", "vsync", true))
	set_msaa(config.get_value("video", "msaa", 1))
