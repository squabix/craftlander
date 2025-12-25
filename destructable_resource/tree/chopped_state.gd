extends State

func enter() -> void:
	Util.disable_all_colliders(root.trunk)
	root.trunk.hide()
	root.chop_particles.global_transform = root.hurtbox.get_child(0).global_transform # Transform particles to center of tree
	root.chop_particles.emitting = true
	%BenchInteractable.enable()
	#%Spawner3D.drop()
