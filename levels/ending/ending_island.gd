class_name EndingIsland
extends Island

@export_group("Curse", "curse")
@export var curse_palette: SkyPalette
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var curse_phase_degrees := 25.0

@export_group("Freed", "freed")
@export var freed_palette: SkyPalette
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var freed_phase_degrees := 70.0
@export var freed_ground: MeshInstance3D
@export var freed_ground_gradient: Texture2D
@export var dead_shrub_prop: IslandProp
@export var dead_tree_prop: IslandProp
@export var dead_skeleton_prop: IslandProp
@export var freed_shrub_props: Array[IslandProp]
@export var freed_tree_props: Array[IslandProp]

@export_group("Fleet")
@export var player_docking_manager: DockingManager
@export var ghost_docking_managers: Array[DockingManager]

var boats: Array[GhostBoat] = []

var _original_speed := 1.0
var _cursed := false


func update_sky_setting(is_first_visit: bool) -> void:
	super(is_first_visit)
	if GameSave.is_captain_defeated():
		apply_freed_look()


func begin_curse() -> void:
	if _cursed:
		return
	_cursed = true

	_original_speed = day_night_cycle.cycle_speed_multiplier
	day_night_cycle.palette = curse_palette
	day_night_cycle.cycle_speed_multiplier = 0.0
	day_night_cycle.jump_to_phase(curse_phase_degrees)


func lift_curse() -> void:
	if _cursed:
		_cursed = false
		day_night_cycle.cycle_speed_multiplier = _original_speed

	apply_freed_look()
	day_night_cycle.jump_to_phase(freed_phase_degrees)
	regrow_dead_plants()


func apply_freed_look() -> void:
	day_night_cycle.palette = freed_palette
	apply_freed_ground()


func apply_freed_ground() -> void:
	if not is_instance_valid(freed_ground) or freed_ground_gradient == null:
		return

	var material := freed_ground.material_override as ShaderMaterial
	if material != null:
		material.set_shader_parameter(&"gradient", freed_ground_gradient)


func add_boat(boat: GhostBoat) -> void:
	boat.cannon.target = player
	boats.append(boat)


func set_cannons(interval: float) -> void:
	for boat in boats:
		if is_instance_valid(boat) and is_instance_valid(boat.cannon):
			boat.cannon.set_fire_interval(interval)
			boat.cannon.set_active(true)


func silence_cannons() -> void:
	for boat in boats:
		if is_instance_valid(boat) and is_instance_valid(boat.cannon):
			boat.cannon.set_active(false)


func sink_boats() -> void:
	for boat in boats:
		if is_instance_valid(boat):
			boat.sink()


func lock_player_boat(locked: bool) -> void:
	var boat := player_docking_manager.boat as PlayerBoat
	if is_instance_valid(boat):
		boat.interactable.enabled = not locked


func regrow_dead_plants() -> void:
	regrow(dead_shrub_prop, freed_shrub_props)
	regrow(dead_tree_prop, freed_tree_props)
	remove_all(dead_skeleton_prop)


func regrow(dead_prop: IslandProp, living_props: Array[IslandProp]) -> void:
	if living_props.is_empty():
		return

	for dead_node in find_placed(dead_prop):
		replace_with_random(dead_node, living_props)


func remove_all(dead_prop: IslandProp) -> void:
	for dead_node in find_placed(dead_prop):
		dead_node.queue_free()


func find_placed(prop: IslandProp) -> Array[Node3D]:
	var placed: Array[Node3D] = []
	if prop == null or prop.scene == null:
		return placed

	for child in prop_populator.get_children():
		if child is Node3D and child.scene_file_path == prop.scene.resource_path:
			placed.append(child)
	return placed


func replace_with_random(dead_node: Node3D, living_props: Array[IslandProp]) -> void:
	var spot := dead_node.global_transform
	var parent := dead_node.get_parent()
	dead_node.queue_free()

	plant(living_props.pick_random(), parent, spot)


func plant(prop: IslandProp, parent: Node, spot: Transform3D) -> void:
	var plant_node := prop.scene.instantiate() as Node3D
	parent.add_child(plant_node)
	plant_node.global_transform = spot
	plant_node.rotate_y(randf() * TAU)
	plant_node.scale = Vector3.ONE * randf_range(prop.min_scale, prop.max_scale)
