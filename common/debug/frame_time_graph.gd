class_name FrameTimeGraph
extends Control

@export_custom(PROPERTY_HINT_NONE, "suffix:frames") var history_size := 240
@export_custom(PROPERTY_HINT_NONE, "suffix:ms") var graph_ceiling := 50.0
@export var frame_time_colors: Dictionary[float, Color] = {
	16.6: Color.LIME_GREEN, # 60 FPS
	33.3: Color.YELLOW, # 30 FPS
	INF: Color.ORANGE_RED,
}

var _frame_times_ms: Array[float] = []


func _ready() -> void:
	set_process(is_visible_in_tree())


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process(is_visible_in_tree())
		if not is_visible_in_tree():
			_frame_times_ms.clear()


func _process(delta: float) -> void:
	_frame_times_ms.append(delta * 1000.0)
	if _frame_times_ms.size() > history_size:
		_frame_times_ms.pop_front()
	queue_redraw()


func _draw() -> void:
	if _frame_times_ms.is_empty():
		return

	var bar_width := size.x / history_size

	for i in _frame_times_ms.size():
		var ms: float = _frame_times_ms[i]
		var bar_height := clampf(ms / graph_ceiling, 0.0, 1.0) * size.y
		var x := i * bar_width
		draw_rect(Rect2(x, size.y - bar_height, bar_width, bar_height), _color_for(ms))


func _color_for(ms: float) -> Color:
	var thresholds := frame_time_colors.keys()
	thresholds.sort()

	for threshold in thresholds:
		if ms <= threshold:
			return frame_time_colors[threshold]

	return frame_time_colors[thresholds[-1]] if not thresholds.is_empty() else Color.WHITE
