@tool
class_name RadialCompass3D
extends Control

enum DirectionMode { NONE, NORTH, CARDINAL, INTERCARDINAL }

static var DIRECTIONS: Array[Direction] = [
	Direction.new("N", 0.0, DirectionMode.NORTH),
	Direction.new("NE", 45.0, DirectionMode.INTERCARDINAL),
	Direction.new("E", 90.0, DirectionMode.CARDINAL),
	Direction.new("SE", 135.0, DirectionMode.INTERCARDINAL),
	Direction.new("S", 180.0, DirectionMode.CARDINAL),
	Direction.new("SW", 225.0, DirectionMode.INTERCARDINAL),
	Direction.new("W", 270.0, DirectionMode.CARDINAL),
	Direction.new("NW", 315.0, DirectionMode.INTERCARDINAL),
]

@export var center_node: Node3D

@export_group("Appearance")
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var radius := 48.0
@export var background_color := Color(0.0, 0.0, 0.0, 0.5)
@export var font: Font:
	get:
		if font == null:
			return ThemeDB.fallback_font
		return font

@export_subgroup("Ring", "ring")
@export var ring_color := Color(1.0, 1.0, 1.0, 0.8)
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var ring_thickness := 1.5
@export var ring_segment_count := 48

@export_subgroup("Ticks", "ticks")
@export var ticks_enabled := true
@export var ticks_color := Color(1.0, 1.0, 1.0, 0.5)
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var ticks_interval_degrees := 45.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var ticks_length := 6.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var ticks_thickness := 1.0

@export_subgroup("Directions", "directions")
@export var directions_mode := DirectionMode.CARDINAL
@export var directions_color := Color.WHITE
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var directions_font_size := 14
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var directions_offset := 10.0

@export_subgroup("Pointer", "pointer")
@export var pointer_enabled := true
@export var pointer_color := Color(1.0, 0.85, 0.2)
@export var pointer_shape: PackedVector2Array = PackedVector2Array(
	[
		Vector2(0.0, -4.0),
		Vector2(-5.0, 4.0),
		Vector2(5.0, 4.0),
	],
)

@export_group("Markers", "marker")
@export var marker_default_color := Color.RED
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var marker_size := 8.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var marker_min_size := 4.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var marker_max_size := 12.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var marker_offset := 0.0
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var marker_text_offset := 7.0

@export_subgroup("Name", "marker_name")
@export var marker_name_enabled := true
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var marker_name_size := 11

@export_subgroup("Distance", "marker_distance")
@export var marker_distance_enabled := true
@export var marker_distance_unit := "m"

@export var marker_text_format := "%s %d%s"

var _markers: Array[CompassMarker3D] = []


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var origin := size * 0.5
	var heading := _get_heading_degrees()

	draw_circle(origin, radius, background_color)
	draw_arc(origin, radius, 0.0, TAU, ring_segment_count, ring_color, ring_thickness)

	if ticks_enabled:
		_draw_ticks(origin, heading)

	if directions_mode != DirectionMode.NONE:
		_draw_directions(origin, heading)

	if pointer_enabled:
		_draw_pointer(origin)

	if is_instance_valid(center_node):
		for marker in _markers:
			if marker.is_currently_visible():
				_draw_marker(origin, heading, marker)


func add_marker(marker: CompassMarker3D) -> void:
	if marker not in _markers:
		_markers.append(marker)


func remove_marker(marker: CompassMarker3D) -> void:
	_markers.erase(marker)


func clear_markers() -> void:
	_markers.clear()


func _get_heading_degrees() -> float:
	if not is_instance_valid(center_node):
		return 0.0
	var forward := -center_node.global_transform.basis.z
	return rad_to_deg(atan2(forward.x, -forward.z))


func _get_bearing_degrees(world_position: Vector3) -> float:
	var direction := world_position - center_node.global_position
	return rad_to_deg(atan2(direction.x, -direction.z))


func _point_on_ring(origin: Vector2, relative_degrees: float, at_radius: float) -> Vector2:
	var angle := deg_to_rad(relative_degrees)
	return origin + Vector2(sin(angle), -cos(angle)) * at_radius


func _draw_ticks(origin: Vector2, heading: float) -> void:
	if ticks_interval_degrees <= 0.0:
		return

	var degrees := 0.0
	while degrees < 360.0:
		var relative := degrees - heading
		var outer := _point_on_ring(origin, relative, radius)
		var inner := _point_on_ring(origin, relative, radius - ticks_length)
		draw_line(inner, outer, ticks_color, ticks_thickness)
		degrees += ticks_interval_degrees


func _draw_directions(origin: Vector2, heading: float) -> void:
	var label_radius := radius - directions_offset
	var ascent := font.get_ascent(directions_font_size)
	for direction in DIRECTIONS:
		if direction.mode > directions_mode:
			continue
		
		var relative := direction.degrees - heading
		var text_width := font.get_string_size(direction.label, HORIZONTAL_ALIGNMENT_CENTER, -1, directions_font_size).x
		var text_position := _point_on_ring(origin, relative, label_radius) + Vector2(-text_width * 0.5, ascent * 0.5)
		
		draw_string(
			font,
			text_position,
			direction.label,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			directions_font_size,
			directions_color,
		)


func _draw_pointer(origin: Vector2) -> void:
	if pointer_shape.is_empty():
		return

	var anchor := origin + Vector2(0.0, -radius)
	
	var points := PackedVector2Array()
	for point in pointer_shape:
		points.append(anchor + point)
	
	draw_polygon(points, PackedColorArray([pointer_color]))


func _draw_marker(origin: Vector2, heading: float, marker: CompassMarker3D) -> void:
	var world_position := marker.get_world_position()
	var relative := _get_bearing_degrees(world_position) - heading
	var distance := center_node.global_position.distance_to(world_position)
	var marker_diameter := _get_marker_size(marker, distance)
	var marker_position := _point_on_ring(origin, relative, radius - marker_diameter * 0.5 + marker_offset)
	var marker_color := marker.color if marker.color.a > 0.0 else marker_default_color

	draw_circle(marker_position, marker_diameter * 0.5, marker_color)

	var show_name := marker_name_enabled and not marker.name.is_empty()
	var show_distance := marker_distance_enabled and marker.show_distance

	var text := ""
	if show_name and show_distance:
		text = marker_text_format % [marker.name, int(round(distance)), marker_distance_unit]
	elif show_name:
		text = marker.name
	elif show_distance:
		text = "%d%s" % [int(round(distance)), marker_distance_unit]

	if text.is_empty():
		return

	var text_position := marker_position + Vector2(0.0, marker_diameter + marker_text_offset)
	draw_string(
		font,
		text_position,
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		marker_name_size,
		marker_color,
	)


func _get_marker_size(marker: CompassMarker3D, distance: float) -> float:
	if marker.size_curve == null:
		return marker_size
	var t := marker.size_curve.sample(distance)
	return lerp(marker_min_size, marker_max_size, t)


class Direction:
	var label: String
	var degrees: float
	var mode: DirectionMode


	func _init(initial_label: String, initial_degrees: float, initial_mode: DirectionMode) -> void:
		label = initial_label
		degrees = initial_degrees
		mode = initial_mode
