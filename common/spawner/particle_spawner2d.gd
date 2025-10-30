class_name ParticleSpawner2D
extends Spawner2D

@export var free_on_finish: bool = true

func initialize_instance(instance: Node2D) -> void:
	emit_particles(instance)

func emit_particles(node: Node) -> void:
	for child in node.get_children():
		emit_particles(child)
	if node is CPUParticles2D or node is GPUParticles2D:
		node.emitting = true
		if free_on_finish:
			await node.finished
			if is_instance_valid(node):
				node.queue_free()
	
