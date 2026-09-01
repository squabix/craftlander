extends Node

signal overlay_toggled(is_open: bool)

const APP_ID := 5051720
const STATS_FLUSH_INTERVAL_S := 5.0

var is_active := false

var _stats_dirty := false
var _flush_timer: Timer
var _was_paused_before_overlay := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_steam()

	_flush_timer = Timer.new()
	_flush_timer.wait_time = STATS_FLUSH_INTERVAL_S
	_flush_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_flush_timer.timeout.connect(_on_flush_timeout)
	add_child(_flush_timer)
	_flush_timer.start()

	add_child(GameAchievements.new())


func _process(_delta: float) -> void:
	if is_active:
		Steam.run_callbacks()


func unlock_achievement(id: StringName) -> void:
	if not is_active:
		return
	var state: Dictionary = Steam.getAchievement(id)
	if state.get("achieved", false):
		return
	Steam.setAchievement(id)
	_stats_dirty = true


func get_stat(id: StringName) -> int:
	if not is_active:
		return 0
	return Steam.getStatInt(id)


func set_stat(id: StringName, value: int) -> void:
	if not is_active:
		return
	Steam.setStatInt(id, value)
	_stats_dirty = true
	if OS.is_debug_build():
		print("SteamManager: %s = %s" % [id, value])


func increment_stat(id: StringName, amount: int = 1) -> void:
	set_stat(id, get_stat(id) + amount)


func update_status(status_text: String) -> void:
	if not is_active:
		return
	Steam.setRichPresence("status", status_text)
	Steam.setRichPresence("steam_display", "#StatusGeneric")


func cloud_write(filename: String, data: PackedByteArray) -> void:
	if not is_active:
		return
	Steam.fileWrite(filename, data)


func cloud_read(filename: String) -> PackedByteArray:
	if not cloud_file_exists(filename):
		return PackedByteArray()
	var size: int = Steam.getFileSize(filename)
	if size <= 0:
		return PackedByteArray()
	var result: Dictionary = Steam.fileRead(filename, size)
	return result.get("buf", PackedByteArray())


func cloud_file_exists(filename: String) -> bool:
	return is_active and Steam.fileExists(filename)


func cloud_timestamp(filename: String) -> int:
	if not cloud_file_exists(filename):
		return 0
	return Steam.getFileTimestamp(filename)


func trigger_screenshot() -> void:
	if not is_active:
		return
	Steam.triggerScreenshot()


func _init_steam() -> void:
	if not Engine.has_singleton("Steam"):
		return

	OS.set_environment("SteamAppId", str(APP_ID))
	OS.set_environment("SteamGameId", str(APP_ID))

	var init_result: Dictionary = Steam.steamInitEx(APP_ID)
	is_active = init_result.get("status", 1) == 0
	if not is_active:
		push_warning("SteamManager: init failed (%s) — Steam features disabled" % init_result.get("verbal", "unknown"))
		return

	Steam.overlay_toggled.connect(_on_overlay_toggled)
	Steam.requestUserStats(Steam.getSteamID())


func _on_overlay_toggled(is_open: bool) -> void:
	overlay_toggled.emit(is_open)
	if is_open:
		_was_paused_before_overlay = get_tree().paused
		get_tree().paused = true
	else:
		get_tree().paused = _was_paused_before_overlay


func _on_flush_timeout() -> void:
	if not is_active or not _stats_dirty:
		return
	Steam.storeStats()
	_stats_dirty = false
