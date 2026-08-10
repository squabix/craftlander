extends Node

signal config_loaded

const SECTION_AUDIO := "audio"

const SAVE_PATH := "user://settings.cfg"
var config := ConfigFile.new()
var is_config_loaded := false


func _ready() -> void:
	load_settings()

func save_settings() -> void:
	config.save(SAVE_PATH)

func load_settings() -> void:
	var err = config.load(SAVE_PATH)
	if err != OK:
		Util.node_error("%s failed to load config", self)
		return
	is_config_loaded = true
	config_loaded.emit()
	print("%s loaded config" % self)

func set_volume(bus_name: StringName, value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	set_value(SECTION_AUDIO, bus_name, value)
	save_settings()

func set_vsync(enabled: bool) -> void:
	var mode = DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)
	set_value("video", "vsync", enabled)

func set_value(section: String, key: String, value: Variant) -> void:
	config.set_value(section, key, value)
	save_settings()

func set_msaa(index: int) -> void:
	get_viewport().msaa_3d = index as Viewport.MSAA
	set_value("video", "msaa", index)

func apply_video_settings() -> void:
	var mode = config.get_value("video", "mode", DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_mode(mode)
	set_vsync(config.get_value("video", "vsync", true))
	set_msaa(config.get_value("video", "msaa", 1))
