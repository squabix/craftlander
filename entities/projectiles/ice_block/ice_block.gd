class_name IceBlockProjectile
extends HitProjectile3D

@onready var spawn_animation: AnimationPlayer = $SpawnAnimation


func _ready() -> void:
	super()
	# Hold off falling until the spawn-in animation finishes.
	set_physics_process(false)
	spawn_animation.animation_finished.connect(_on_spawn_animation_finished)
	spawn_animation.play(&"spawn")


func _on_spawn_animation_finished(_anim_name: StringName) -> void:
	set_physics_process(true)


# Dropped straight down onto a raycasted target rather than thrown, so it
# ignores the caster's velocity/aim direction (speed/launch_direction are unused).
func launch(_inherited_velocity := Vector3.ZERO) -> void:
	velocity = Vector3.ZERO
