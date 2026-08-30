class_name ProjectileSpawner3D
extends Spawner3D

@export var projectile_scene: PackedScene
@export var damage: Damage
@export var source: Node


func create_instance() -> Node3D:
	if projectile_scene == null:
		Util.node_error("%s cannot create instance without a projectile_scene", self)
		return null
	return projectile_scene.instantiate()


func initialize_instance(instance: Node3D) -> void:
	super(instance)
	var projectile := instance as HitProjectile3D
	if projectile == null:
		return
	if damage != null:
		var instance_damage: Damage = damage.duplicate()
		instance_damage.source = source
		projectile.damage = instance_damage
	projectile.launch()
