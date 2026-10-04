class_name EnemyCompassTracker
extends Node

@export var compass: RadialCompass3D
@export var center_node: Node3D
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var detection_radius := 40.0
@export var marker_color := Color.RED
@export var size_curve: Curve

var _tracked_markers: Dictionary[Entity3D, CompassMarker3D] = {}


func refresh() -> void:
	if not is_instance_valid(center_node):
		return

	var nearby: Dictionary[Entity3D, bool] = {}
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var entity := node as Entity3D
		if not is_instance_valid(entity):
			continue
		if entity.global_position.distance_to(center_node.global_position) > detection_radius:
			continue

		nearby[entity] = true
		if not _tracked_markers.has(entity):
			_tracked_markers[entity] = _create_marker(entity)

	for entity in _tracked_markers.keys():
		if not is_instance_valid(entity):
			continue
		if entity in nearby:
			continue
		_untrack(entity)


func _create_marker(entity: Entity3D) -> CompassMarker3D:
	var marker := CompassMarker3D.new()
	marker.target = entity
	marker.color = marker_color
	marker.size_curve = size_curve
	entity.tree_exiting.connect(_on_entity_tree_exiting.bind(entity))
	compass.add_marker(marker)
	return marker


func _on_entity_tree_exiting(entity: Entity3D) -> void:
	_untrack(entity)


func _untrack(entity: Entity3D) -> void:
	if not _tracked_markers.has(entity):
		return

	var exiting_callable := _on_entity_tree_exiting.bind(entity)
	if entity.tree_exiting.is_connected(exiting_callable):
		entity.tree_exiting.disconnect(exiting_callable)

	compass.remove_marker(_tracked_markers[entity])
	_tracked_markers.erase(entity)
