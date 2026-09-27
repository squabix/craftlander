class_name GhostTraits
extends Node

const GROUP_GHOSTS := &"ghosts"
const GROUP_EXEMPT := &"skin_exempt"

const GHOST_MATERIAL := preload("res://assets/materials/ghost.tres")
const GHOST_MATERIAL_REPLACE_BLACKLIST := [preload("res://assets/materials/glowing_eye.tres")]

const GHOST_BUS := &"SFX Ghost"
const CULLING_RADIUS := 1000.0
const SPAWN_COLOR := Color(0.55, 1.0, 1.0)

@export var entity: Entity3D
@export var ghostify_on_ready := false
@export var is_ranged := false
@export var animates_locomotion := false
@export var material: Material = GHOST_MATERIAL
@export var override_materials := true
@export var projectile_acl: ACL

@export_group("Spawning", "spawn")
@export var spawn_effect_enabled := true
@export var spawn_start_scale := 0.2
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var spawn_duration := 0.7

@export_group("Multipliers", "multiplier")
@export var multiplier_damage := 1.3
@export var multiplier_health := 1.3

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
	apply_multipliers()
	route_sounds()
	if is_instance_valid(coordinator):
		coordinator.register(self)


func play_spawn_in() -> void:
	if not spawn_effect_enabled:
		return

	var center := entity.global_position + Vector3.UP
	EnemyVfx.teleport(Spawner3D.root, center, SPAWN_COLOR)
	EnemyVfx.shockwave(Spawner3D.root, entity.global_position, SPAWN_COLOR, 3.0)

	var visuals := entity.get_node_or_null(^"Visuals") as Node3D
	if visuals == null:
		return
	
	var base_scale := visuals.scale
	visuals.scale = base_scale * spawn_start_scale
	
	var tween := entity.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, ^"scale", base_scale, spawn_duration)


func allow_specials(allowed: bool) -> void:
	if is_instance_valid(chasing_state) and is_instance_valid(chasing_state.rhythm):
		chasing_state.rhythm.enabled = allowed


func get_goal_distance() -> float:
	if is_instance_valid(chasing_state):
		return chasing_state.advance_goal_distance
	return 1.5


func route_sounds() -> void:
	for node in Util.find_children_of_class(entity, &"AudioStreamPlayer3D"):
		route_player(node as AudioStreamPlayer3D)

	for node in Util.find_children_of_class(entity, &"AudioSpawner3D"):
		var spawner := node as AudioSpawner3D
		if spawner.override_stream != null:
			spawner.override_bus = GHOST_BUS
		spawner.spawned.connect(route_player)


func route_player(player: Node3D) -> void:
	var audio_player := player as AudioStreamPlayer3D
	if is_instance_valid(audio_player) and audio_player.bus == &"SFX":
		audio_player.bus = GHOST_BUS


func apply_multipliers() -> void:
	if multiplier_damage != 1.0:
		entity.set_meta(Damage.MULTIPLIER_META, multiplier_damage)

	var health := Health.search(entity)
	if multiplier_health != 1.0 and health != null:
		scale_health(health)


func scale_health(health: Health) -> void:
	health.hp *= multiplier_health
	if health.max_hp <= 0.0:
		return
	health.base_max_hp *= multiplier_health
	health.max_hp *= multiplier_health
	health.hp_changed.emit()


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
	apply_material_to(projectile)


func apply_material() -> void:
	apply_material_to(entity)


func apply_material_to(root: Node) -> void:
	for node in Util.find_children_of_class(root, &"MeshInstance3D"):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.is_in_group(GROUP_EXEMPT) or mesh_instance.mesh == null or is_held_item_visual(mesh_instance):
			continue
		
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if not override_materials:
			continue
		for surface in mesh_instance.mesh.get_surface_count():
			if mesh_instance.get_active_material(surface) in GHOST_MATERIAL_REPLACE_BLACKLIST:
				continue
			mesh_instance.set_surface_override_material(surface, material)


func is_held_item_visual(node: Node) -> bool:
	var parent := node.get_parent()
	while parent != null and parent != entity:
		if parent is ItemVisualsContainer3D:
			return true
		parent = parent.get_parent()
	return false
