extends Node

signal config_loaded

const SECTION_AUDIO := "audio"
const SECTION_VIDEO := "video"
const SECTION_GAMEPLAY := "gameplay"

const ENVIRONMENT_PATH := "res://assets/default_environment.tres"
const SHADOW_ATLAS_SIZES: Array[int] = [1024, 2048, 4096, 8192]
const FPS_CAPS: Array[int] = [0, 30, 60, 120, 144]

const SAVE_PATH := "user://settings.cfg"
var config := ConfigFile.new()
var is_config_loaded := false


func _ready() -> void:
	load_settings()
	apply_video_settings()

func save_settings() -> void:
	config.save(SAVE_PATH)

func load_settings() -> void:
	var err = config.load(SAVE_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		Util.node_error("%s failed to load config", self)
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
	set_value(SECTION_VIDEO, "vsync", enabled)

func set_value(section: String, key: String, value: Variant) -> void:
	config.set_value(section, key, value)
	save_settings()

func set_msaa(index: int) -> void:
	get_viewport().msaa_3d = index as Viewport.MSAA
	set_value(SECTION_VIDEO, "msaa", index)

func set_window_mode(mode: DisplayServer.WindowMode) -> void:
	DisplayServer.window_set_mode(mode)
	set_value(SECTION_VIDEO, "mode", mode)

func set_max_fps(fps: int) -> void:
	Engine.max_fps = fps
	set_value(SECTION_VIDEO, "max_fps", fps)

func set_resolution_scale(value: float) -> void:
	get_viewport().scaling_3d_scale = value
	set_value(SECTION_VIDEO, "resolution_scale", value)

func set_shadow_quality(index: int) -> void:
	RenderingServer.directional_shadow_atlas_set_size(SHADOW_ATLAS_SIZES[index], true)
	set_value(SECTION_VIDEO, "shadow_quality", index)

func set_ssao_enabled(enabled: bool) -> void:
	var environment := get_shared_environment()
	if environment != null:
		environment.ssao_enabled = enabled
	set_value(SECTION_VIDEO, "ssao_enabled", enabled)

func set_glow_enabled(enabled: bool) -> void:
	var environment := get_shared_environment()
	if environment != null:
		environment.glow_enabled = enabled
	set_value(SECTION_VIDEO, "glow_enabled", enabled)

func get_shared_environment() -> Environment:
	return load(ENVIRONMENT_PATH) as Environment

func apply_video_settings() -> void:
	set_window_mode(config.get_value(SECTION_VIDEO, "mode", DisplayServer.WINDOW_MODE_WINDOWED))
	set_vsync(config.get_value(SECTION_VIDEO, "vsync", true))
	set_msaa(config.get_value(SECTION_VIDEO, "msaa", 1))
	set_max_fps(config.get_value(SECTION_VIDEO, "max_fps", 0))
	set_resolution_scale(config.get_value(SECTION_VIDEO, "resolution_scale", 1.0))
	set_shadow_quality(config.get_value(SECTION_VIDEO, "shadow_quality", 1))
	set_ssao_enabled(config.get_value(SECTION_VIDEO, "ssao_enabled", true))
	set_glow_enabled(config.get_value(SECTION_VIDEO, "glow_enabled", true))
