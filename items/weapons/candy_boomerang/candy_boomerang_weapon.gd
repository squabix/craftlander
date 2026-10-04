class_name CandyBoomerangWeapon
extends ProjectileWeapon

class ReturnedEvent extends ItemEvent:
	func _init() -> void:
		name = &"boomerang_returned"

var is_thrown := false


func start_use() -> bool:
	if is_thrown or spawner == null:
		return true

	var projectile := spawner.spawn() as CandyBoomerangProjectile
	if projectile == null:
		return true

	is_thrown = true
	projectile.returned.connect(_on_returned, CONNECT_ONE_SHOT)
	return true


func _on_returned() -> void:
	is_thrown = false
	trigger_event.call_deferred(ReturnedEvent.new())
