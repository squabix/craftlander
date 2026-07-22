@tool
class_name MeshInstanceAggregator3D
extends Node3D

static var aggregated_mesh_instances: Dictionary[MeshInstance3D, MeshInstanceAggregator3D]

@export_tool_button("Aggregate", "MultiMesh") var aggregate_action: Callable = aggregate
@export_tool_button("Reset", "Reload") var reset_action: Callable = reset

@export var mesh_source: Node
@export var aggregate_on_ready := false
@export var use_material_override := true
@export var multi_instance_name_format := "MultiMesh_%s"

@export_group("Instance Visibility")
@export var invert_instance_visibility := true
@export var reset_instance_visibility := true

var generated_multimeshes: Array[MultiMeshInstance3D] = []
var instance_registry: Dictionary[MeshInstance3D, MultiMeshData] = { }


static func disassociate_mesh_instance(instance: MeshInstance3D) -> void:
	var aggregator: MeshInstanceAggregator3D = aggregated_mesh_instances.get(instance, null)
	if not is_instance_valid(aggregator):
		if is_instance_valid(instance):
			printerr("Could not find aggregator for %s" % instance)
		return

	var data: MultiMeshData = aggregator.instance_registry.get(instance, null)
	if data == null:
		printerr("%s could not find data for %s in instance registry" % [aggregator, instance])
		return

	aggregator.disconnect_visibility_inversion(instance)
	data.hide()
	aggregator.instance_registry.erase(instance)
	aggregated_mesh_instances.erase(instance)

	if aggregator.invert_instance_visibility:
		instance.show()


static func get_material_override(mesh_instance: MeshInstance3D) -> Material:
	if mesh_instance == null:
		return null

	return mesh_instance.material_override


func _ready() -> void:
	if aggregate_on_ready:
		aggregate.call_deferred()


func get_all_mesh_instances() -> Array[MeshInstance3D]:
	var instances: Array[MeshInstance3D]
	instances.assign(Util.find_children_of_class(mesh_source, &"MeshInstance3D"))
	return instances


func get_mesh_groups() -> Dictionary[Mesh, Array]:
	var all_mesh_instances := get_all_mesh_instances()
	var instance_key_groups: Dictionary[StringName, Array] = { }

	# Group instances by their unique combination of mesh + overrides
	for instance in all_mesh_instances:
		if not instance.mesh:
			continue

		var key := _get_instance_group_key(instance)
		if not instance_key_groups.has(key):
			instance_key_groups[key] = []
		instance_key_groups[key].append(instance)

	# Duplicate the meshes and bake the surface overrides directly onto them
	var mesh_groups: Dictionary[Mesh, Array] = { }
	for key in instance_key_groups:
		var group: Array[MeshInstance3D]
		group.assign(instance_key_groups[key])

		var base_instance := group[0]
		var mesh_duplicate: Mesh = base_instance.mesh.duplicate()

		for i in range(base_instance.get_surface_override_material_count()):
			var override := base_instance.get_surface_override_material(i)
			if override == null:
				continue
			mesh_duplicate.surface_set_material(i, override)

		mesh_groups[mesh_duplicate] = group

	return mesh_groups


func add_multi_instance(name_infix: String, material_override: Material = null) -> MultiMeshInstance3D:
	var multi_instance := MultiMeshInstance3D.new()
	multi_instance.name = multi_instance_name_format % name_infix
	add_child(multi_instance)
	generated_multimeshes.append(multi_instance)

	if use_material_override and material_override != null:
		multi_instance.material_override = material_override

	return multi_instance


func generate_multi_mesh(mesh: Mesh, instances: Array[MeshInstance3D], multi_instance: MultiMeshInstance3D) -> MultiMesh:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = instances.size()

	var inverse_global_transform := multi_instance.global_transform.affine_inverse()

	for i in range(instances.size()):
		var instance: MeshInstance3D = instances[i]
		var relative_transform: Transform3D = inverse_global_transform * instance.global_transform

		instance_registry[instance] = MultiMeshData.new(multi_instance, i, relative_transform)
		aggregated_mesh_instances[instance] = self

		instance.hide() # Hide the original mesh source so only the MultiMesh is visible initially
		multimesh.set_instance_transform(i, relative_transform)

		connect_visibility_inversion(instance)

	return multimesh


func aggregate() -> void:
	reset()

	if not is_instance_valid(mesh_source):
		return

	var mesh_groups := get_mesh_groups()

	for mesh in mesh_groups:
		var instances: Array[MeshInstance3D]
		instances.assign(mesh_groups[mesh])
		if instances.is_empty():
			continue

		var multi_instance := add_multi_instance(mesh.resource_name, get_material_override(instances[0]))
		multi_instance.multimesh = generate_multi_mesh(mesh, instances, multi_instance)


func connect_visibility_inversion(instance: MeshInstance3D) -> void:
	if Engine.is_editor_hint():
		return

	if not invert_instance_visibility:
		return

	var callable := _on_instance_visibility_changed.bind(instance)
	if instance.visibility_changed.is_connected(callable):
		return

	instance.visibility_changed.connect(callable)


func disconnect_visibility_inversion(instance: MeshInstance3D) -> void:
	if Engine.is_editor_hint():
		return

	if not is_instance_valid(instance):
		return

	var callable := _on_instance_visibility_changed.bind(instance)
	if not instance.visibility_changed.is_connected(callable):
		return

	instance.visibility_changed.disconnect(callable)


func reset() -> void:
	# Disconnect all bound visibility signals to prevent leaks
	for instance in instance_registry.keys():
		if not is_instance_valid(instance):
			continue
		disconnect_visibility_inversion(instance)

	# Remove generated multi meshes
	for mm in generated_multimeshes:
		Util.safe_free(mm)
	generated_multimeshes.clear()

	for instance in aggregated_mesh_instances:
		if not is_instance_valid(instance):
			continue
		if aggregated_mesh_instances.get(instance, null):
			aggregated_mesh_instances.erase(instance)

	# Make all the original individual mesh instances visible again
	if reset_instance_visibility:
		for instance in get_all_mesh_instances():
			instance.show()

	instance_registry.clear()


func set_instance_visibility(instance: MeshInstance3D, visibility: bool) -> void:
	if not instance_registry.has(instance):
		return

	var data: MultiMeshData = instance_registry[instance]

	if visibility == true:
		data.show()
	else:
		data.hide()


func _get_instance_group_key(instance: MeshInstance3D) -> StringName:
	var key := str(instance.mesh.get_instance_id()) + (
			"_g:null" if instance.material_override == null
			else "_g:%s" % str(instance.material_override.get_instance_id())
	)
	
	for i in range(instance.get_surface_override_material_count()):
		var material := instance.get_surface_override_material(i)
		key += (
				"_s%s:null" % i if material == null
				else "_s%s:%s" % [i, str(material.get_instance_id())]
		)
	return StringName(key)


func _on_instance_visibility_changed(instance: MeshInstance3D) -> void:
	if not invert_instance_visibility:
		return

	# If the source mesh is shown, then hide the multimesh element (and vice versa)
	set_instance_visibility(instance, not instance.is_visible_in_tree())


class MultiMeshData:
	var multi_mesh_instance: MultiMeshInstance3D
	var index: int
	var transform: Transform3D


	func _init(data_instance: MultiMeshInstance3D, data_index: int, data_transform: Transform3D) -> void:
		multi_mesh_instance = data_instance
		index = data_index
		transform = data_transform


	func is_mesh_valid() -> bool:
		return is_instance_valid(multi_mesh_instance) and multi_mesh_instance.multimesh != null


	func show() -> void:
		if not is_mesh_valid():
			return
		multi_mesh_instance.multimesh.set_instance_transform(index, transform)


	func hide() -> void:
		if not is_mesh_valid():
			return
		multi_mesh_instance.multimesh.set_instance_transform(index, Transform3D().scaled(Vector3.ZERO))
