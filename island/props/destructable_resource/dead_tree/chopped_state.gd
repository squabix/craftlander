extends State

@export var trunk: Node3D
@export var chop_particles: GPUParticles3D

@onready var particles_scene := preload("res://particles/puff_particles.tscn")

func enter() -> void:
	Util.safe_free(trunk)
	chop_particles.show()
	chop_particles.global_transform = root.hurtbox.get_child(0).global_transform # Transform particles to center of tree
	chop_particles.emitting = true
