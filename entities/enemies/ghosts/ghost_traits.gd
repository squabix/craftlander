class_name GhostTraits
extends Node

const GROUP_GHOSTS := &"ghosts"
const GROUP_EXEMPT := &"skin_exempt"

const GHOST_MATERIAL := preload("res://assets/materials/ghost.tres")
const GHOST_MATERIAL_REPLACE_BLACKLIST := [preload("res://assets/materials/glowing_eye.tres")]

const CULLING_RADIUS := 1000.0

@export var entity: Entity3D
@export var ghostify_on_ready := false
@export var is_ranged := false
@export var animates_locomotion := false
@export var material: Material = GHOST_MATERIAL
@export var projectile_acl: ACL

@export_group("Movement")
@export var guide: GhostEntityGuide3D
@export var hoverer: Hoverer3D
@export var nav_guide: NavEntityGuide3D
@export var targeting_states: Array[TargetingState]
@export var chasing_state: ChasingState

@export_group("Components")
@export var culling_controller: CullingController3D
@export var projectile_spawners: Array[ProjectileSpawner3D]
@export var inventory: Inventory
@export var dropper: InventoryDropper3D
@export var item_visuals: ItemVisualsContainer3D
@export var item_holder: ItemHolder3D

var _is_ghost := false


func _ready() -> void:
	if ghostify_on_ready:
		ghostify()


func ghostify(coordinator: GhostMeleeCoordinator = null) -> void:
	if _is_ghost:
		return
	_is_ghost = true

	entity.collision_mask = 0
	entity.does_obey_gravity = false
	entity.animate_locomotion = animates_locomotion
	entity.add_to_group(GROUP_GHOSTS)

	swap_guide()
	disable_target_loss()
	update_culling_radius()
	restrict_projectiles()
	strip_drops()
	apply_material()
	if is_instance_valid(coordinator):
		coordinator.register(self)


func get_goal_distance() -> float:
	if is_instance_valid(chasing_state):
		return chasing_state.advance_goal_distance
	return 1.5


func swap_guide() -> void:
	guide.process_mode = Node.PROCESS_MODE_INHERIT
	hoverer.process_mode = Node.PROCESS_MODE_INHERIT
	if is_instance_valid(nav_guide):
		nav_guide.process_mode = Node.PROCESS_MODE_DISABLED
	for state in targeting_states:
		state.guide = guide


func disable_target_loss() -> void:
	if not is_instance_valid(chasing_state):
		return
	
	chasing_state.can_lose_target = false
	chasing_state.advance_in_water = true
	
	var sight := chasing_state.sight
	if is_instance_valid(sight):
		sight.ray_enabled = false
		sight.can_lose_target = false


func update_culling_radius() -> void:
	if not is_instance_valid(culling_controller):
		return
	
	culling_controller.on_screen_process_radius = CULLING_RADIUS
	culling_controller.off_screen_process_radius = CULLING_RADIUS
	culling_controller.on_screen_visible_radius = CULLING_RADIUS


func restrict_projectiles() -> void:
	
	# Restrict entity
	for spawner in projectile_spawners:
		spawner.spawned.connect(restrict_projectile)
	
	# Restrict item
	if not is_instance_valid(item_holder):
		return
	item_holder.updated_instance.connect(restrict_held_instance)
	restrict_held_instance(item_holder.held_item_instance)


func restrict_held_instance(instance: ItemInstance) -> void:
	if instance == null:
		return
	
	var weapon := instance.item as ProjectileWeapon
	if weapon == null or not is_instance_valid(weapon.spawner):
		return
	
	if not weapon.spawner.spawned.is_connected(restrict_projectile):
		weapon.spawner.spawned.connect(restrict_projectile)


func strip_drops() -> void:
	if is_instance_valid(inventory):
		var empty_items: Array[ItemInstance] = []
		inventory.item_instances = empty_items
	
	if is_instance_valid(dropper):
		dropper.death_drop_mode = InventoryDropper3D.DeathDropMode.NONE


func restrict_projectile(instance: Node3D) -> void:
	var projectile := instance as HitProjectile3D
	if projectile == null:
		return
	projectile.target_acl = ACL.resolve(projectile_acl, [])


func apply_material() -> void:
	
	# Apply to entity
	for node in Util.find_children_of_class(entity, &"MeshInstance3D"):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.is_in_group(GROUP_EXEMPT) or mesh_instance.mesh == null:
			continue
		
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in mesh_instance.mesh.get_surface_count():
			if mesh_instance.get_active_material(surface) in GHOST_MATERIAL_REPLACE_BLACKLIST:
				continue
			mesh_instance.set_surface_override_material(surface, material)
	
	# Apply to item
	if is_instance_valid(item_visuals):
		item_visuals.do_disable_shadows = true
		item_visuals.material_override = material
