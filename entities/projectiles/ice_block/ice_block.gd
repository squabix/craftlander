class_name IceBlockProjectile
extends HitProjectile3D

@export var visuals: Node3D
@export var spawn_player: AnimationPlayer
@export var spawn_particle_spawner: ParticleSpawner3D


func _ready() -> void:
	super()
	# Hold off falling until the spawn-in animation finishes
	set_physics_process(false)
	spawn_player.animation_finished.connect(_on_spawn_animation_finished)
	spawn_player.play(&"spawn")
	# The spawner positions us after add_child, so wait until it has before emitting
	spawn_particle_spawner.spawn.call_deferred()
	visuals.rotation.y = randf() * TAU


func _on_spawn_animation_finished(_anim_name: StringName) -> void:
	set_physics_process(true)


func launch(_inherited_velocity := Vector3.ZERO) -> void:
	velocity = Vector3.ZERO


# Falls through hurtboxes; only hitting a body frees it
func _on_hit_node() -> void:
	pass
