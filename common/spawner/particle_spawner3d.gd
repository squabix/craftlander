class_name ParticleSpawner3D
extends SceneSpawner3D

@export var free_on_finish := true


func initialize_instance(instance: Node3D) -> void:
	super(instance)
	emit_particles(instance, free_on_finish)


func defers_when_exiting_tree() -> bool:
	return true


func _call_initializer(instance: Node3D, use_deferred_add: bool) -> void:
	if use_deferred_add:
		# initialize_instance.call_deferred(instance) would bind to self, which can
		# already be freed by the time it runs if spawn_on_exit_tree fired because our
		# own parent is dying (e.g. a projectile parented under the tree root freeing
		# itself) - emit_particles is static so it only needs instance to still be alive.
		emit_particles.call_deferred(instance, free_on_finish)
	else:
		initialize_instance(instance)


static func emit_particles(node: Node, free_node_on_finish := true) -> void:
	for child in node.get_children():
		emit_particles(child)

	if not (node is CPUParticles3D or node is GPUParticles3D):
		return

	node.emitting = true
	if free_node_on_finish:
		node.finished.connect(Util.safe_free.bind(node))
