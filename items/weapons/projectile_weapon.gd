class_name ProjectileWeapon
extends Item

@export var damage: Damage

@export_group("Scene")
@export var spawner_scene_path := "ProjectileSpawner" # Node path inside the scene containing visual meshes, particles, animations, etc.

var spawner: ProjectileSpawner3D


func clear_nodes() -> void:
	super()
	spawner = null


func set_up_scene() -> void:
	if scene_instance == null:
		return
	super()
	spawner = scene_instance.get_node("ProjectileSpawner")
	damage.source = root
	spawner.damage = damage
	spawner.source = root


func start_use() -> bool:
	if spawner != null:
		spawner.spawn()
	return true
