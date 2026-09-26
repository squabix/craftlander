class_name GhostVFX
extends Object


const IMPACT_SCENE := preload("res://particles/ghost_impact_particles.tscn")
const TELEPORT_SCENE := preload("res://particles/ghost_teleport_particles.tscn")
const SHOCKWAVE_SCENE := preload("res://particles/ghost_shockwave_particles.tscn")
const CHARGE_SCENE := preload("res://particles/ghost_charge_particles.tscn")
const AURA_SCENE := preload("res://particles/ghost_aura_particles.tscn")


static func impact(parent: Node, at: Vector3, color: Color, direction := Vector3.UP) -> void:
	_burst(IMPACT_SCENE, parent, at, color, direction)


static func teleport(parent: Node, at: Vector3, color: Color) -> void:
	_burst(TELEPORT_SCENE, parent, at, color, Vector3.UP)


static func shockwave(parent: Node, at: Vector3, color: Color, radius: float) -> void:
	var particles := _spawn(SHOCKWAVE_SCENE, parent, at, color)
	particles.set_radius(radius)
	particles.emitting = true


static func charge(parent: Node, at: Vector3, color: Color, radius: float) -> AdjustableParticles3D:
	return _start_continuous(CHARGE_SCENE, parent, at, color, radius)


static func aura(parent: Node, at: Vector3, color: Color, radius: float) -> AdjustableParticles3D:
	return _start_continuous(AURA_SCENE, parent, at, color, radius)


static func _burst(scene: PackedScene, parent: Node, at: Vector3, color: Color, direction: Vector3) -> void:
	var particles := _spawn(scene, parent, at, color)
	particles.process_material.direction = direction
	particles.emitting = true


static func _start_continuous(scene: PackedScene, parent: Node, at: Vector3, color: Color, radius: float) -> AdjustableParticles3D:
	var particles := _spawn(scene, parent, at, color)
	particles.set_radius(radius)
	particles.emitting = true
	return particles


static func _spawn(scene: PackedScene, parent: Node, at: Vector3, color: Color) -> AdjustableParticles3D:
	var particles := scene.instantiate() as AdjustableParticles3D
	parent.add_child(particles)
	particles.global_position = at
	particles.set_tint(color)
	return particles
