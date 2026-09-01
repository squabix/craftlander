class_name PerfCountersLabel
extends Label


func refresh() -> void:
	text = (
		"Draw calls: %d   Primitives: %d\n"
		+ "Objects: %d   Nodes: %d   Orphans: %d\n"
		+ "Entities: %d   Culled: %d/%d"
	) % [
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.OBJECT_COUNT),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		Entity3D.active_count,
		CullingController3D.culled_count,
		CullingController3D.active_count,
	]
