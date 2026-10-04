@tool
class_name VolumeSlider
extends HSlider

@export var bus: StringName
@export_tool_button("Default Limits", "AudioStreamPlayer") var default_limits_action := default_limits


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	value_changed.connect(set_volume.unbind(1))
	if not GameSettings.is_config_loaded:
		await GameSettings.config_loaded
	value = GameSettings.get_volume(bus)
	set_volume()


func default_limits() -> void:
	min_value = 0.0
	max_value = 1.0


func get_bus_index() -> int:
	return AudioServer.get_bus_index(bus)


func set_volume() -> void:
	if not GameSettings.apply_bus_volume(bus, value):
		return

	GameSettings.set_value(GameSettings.SECTION_AUDIO, bus, value)
