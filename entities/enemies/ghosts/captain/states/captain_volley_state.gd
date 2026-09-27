class_name CaptainVolleyState
extends VolleyAttackState

const CANNON_BLEND_TIME := 0.3

@export var cannon_holder: ItemHolder3D

var captain: GhostCaptain:
	get:
		return root as GhostCaptain


func start_wind_up(origin: Vector3, duration: float) -> PlanarTelegraph3D:
	var telegraph := super(origin, duration)
	captain.cannon_aim.raise(CANNON_BLEND_TIME)
	return telegraph


func update_aim(telegraph: PlanarTelegraph3D) -> void:
	var player := captain.get_player()
	if player != null:
		captain.cannon_aim.aim_point = player.global_position + Vector3.UP * aim_height
	super(telegraph)


func get_aim_direction() -> Vector3:
	return captain.cannon_aim.get_aim_direction()


func get_spawner() -> ProjectileSpawner3D:
	var weapon := cannon_holder.get_held_item() as ProjectileWeapon
	return null if weapon == null else weapon.spawner


func shoot() -> void:
	super()
	captain.cannon_aim.lower(CANNON_BLEND_TIME)
