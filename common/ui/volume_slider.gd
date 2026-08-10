@tool
class_name VolumeSlider
extends HSlider

@export var bus: StringName
@export_tool_button("Default Limits", "AudioStreamPlayer") var default_limits_action := default_limits


func _ready() -> void:
	drag_ended.connect(set_volume.unbind(1))
	if not GameSettings.is_config_loaded:
		await GameSettings.config_loaded
	value = GameSettings.config.get_value(GameSettings.SECTION_AUDIO, bus, 0.8)
	set_volume()


func default_limits() -> void:
	min_value = 0.0
	max_value = 1.0


func get_bus_index() -> int:
	return AudioServer.get_bus_index(bus)


func set_volume() -> void:
	var bus_index := get_bus_index()
	if bus_index == -1:
		return

	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	GameSettings.set_value(GameSettings.SECTION_AUDIO, bus, value)
