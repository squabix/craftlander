class_name ParticleSpawner3D
extends Spawner3D

@export var free_on_finish := true


func initialize_instance(instance: Node3D) -> void:
	emit_particles(instance, free_on_finish)


static func emit_particles(node: Node, free_node_on_finish := true) -> void:
	for child in node.get_children():
		emit_particles(child)

	if not (node is CPUParticles3D or node is GPUParticles3D):
		return

	node.emitting = true
	if free_node_on_finish:
		node.finished.connect(Util.safe_free.bind(node))
