class_name TimerLabel
extends Label

signal time_reset
signal time_ended
signal started
signal stopped
signal ticked

enum TimerMode { STOPWATCH, COUNTDOWN }

@export var active: bool
@export var mode: TimerMode
@export var start_time: float
@export var multiplier: float = 1.0
@export var autoreset: bool
@export var auto_adjust_display: bool

@export_group("Displayed Times")
@export var show_hours: bool = false
@export var show_minutes: bool = true
@export var show_seconds: bool = true
@export var show_milliseconds: bool = false

var time: float
var last_text: String = text


func _ready() -> void:
	time = start_time


func _process(delta: float) -> void:
	if active:
		update_time(delta)
		update_text()


func get_time_passed() -> float:
	if mode == TimerMode.COUNTDOWN:
		return start_time - time
	return time


func start() -> void:
	if active == true:
		return
	active = true
	started.emit()


func stop() -> void:
	if active == false:
		return
	active = false
	stopped.emit()


func update_time(delta: float) -> float:
	var time_change: float = delta * multiplier
	if mode == TimerMode.COUNTDOWN:
		time_change *= -1.0
	time = max(0.0, time + time_change)
	if time == 0.0:
		time_ended.emit()
		if autoreset:
			reset_time()
		else:
			stop()
	return time_change


func restart() -> void:
	reset_time()
	start()


func update_text() -> void:
	var total_seconds: int = int(time)

	if auto_adjust_display:
		if total_seconds >= 1:
			show_seconds = true
		if total_seconds >= 60:
			show_minutes = true
		if total_seconds >= 360:
			show_hours = true

	var ms: int = int((time - total_seconds) * 1000)
	var seconds: int = total_seconds % 60
	var minutes: int = int(total_seconds / 60.0) % 60
	var hours: int = int(total_seconds / 3600.0)

	var parts: PackedStringArray = []

	if show_hours:
		parts.append("%02d" % hours)
	if show_minutes:
		parts.append("%02d" % minutes)
	if show_seconds:
		parts.append("%02d" % seconds)

	var formatted_time = ":".join(parts)

	if show_milliseconds:
		formatted_time += ".%03d" % ms

	text = formatted_time

	if text != last_text:
		ticked.emit()
		last_text = text


func reset_time() -> void:
	time = start_time
	time_reset.emit()
