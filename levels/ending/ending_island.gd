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
@export var freed_shrub_prop: IslandProp
@export var freed_tree_props: Array[IslandProp]
@export var freed_small_props: Array[IslandProp]
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var freed_tree_clearance := 8.0
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var freed_small_clearance := 3.0

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
	regrow_shrubs()


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


func regrow_shrubs() -> void:
	if freed_shrub_prop == null or freed_tree_props.is_empty():
		return

	var shrubs := find_shrubs()
	var occupied := find_occupied()
	var keep_clear := find_keep_clear()

	shrubs.shuffle()
	for shrub in shrubs:
		regrow_shrub(shrub, occupied, keep_clear)


func find_shrubs() -> Array[Node3D]:
	var shrubs: Array[Node3D] = []
	for child in prop_populator.get_children():
		if is_shrub(child):
			shrubs.append(child as Node3D)
	return shrubs


func find_occupied() -> Array[Vector3]:
	var radii := get_prop_radii()
	var occupied: Array[Vector3] = []
	for child in prop_populator.get_children():
		var node := child as Node3D
		if node == null or is_shrub(node):
			continue

		var radius: float = radii.get(node.scene_file_path, 0.0)
		if radius > 0.0:
			occupied.append(Vector3(node.global_position.x, node.global_position.z, radius))
	return occupied


func find_keep_clear() -> Array[Vector2]:
	var keep_clear: Array[Vector2] = []
	for child in prop_populator.get_children():
		if child is TreasureChest:
			keep_clear.append(Vector2(child.global_position.x, child.global_position.z))
	return keep_clear


func get_prop_radii() -> Dictionary[String, float]:
	var radii: Dictionary[String, float] = { }
	var known: Array[IslandProp] = []
	known.assign(prop_populator.prop_quantities.keys())
	known.append_array(freed_tree_props)
	known.append_array(freed_small_props)

	for prop in known:
		if prop.scene != null:
			radii[prop.scene.resource_path] = prop.radius
	return radii


func is_shrub(node: Node) -> bool:
	return node is Node3D and node.scene_file_path == freed_shrub_prop.scene.resource_path


func regrow_shrub(shrub: Node3D, occupied: Array[Vector3], keep_clear: Array[Vector2]) -> void:
	var spot := shrub.global_transform
	shrub.queue_free()

	var prop := pick_fitting_prop(spot.origin, occupied, keep_clear)
	if prop == null:
		return

	occupied.append(Vector3(spot.origin.x, spot.origin.z, prop.radius))
	plant(prop, shrub.get_parent(), spot)


func plant(prop: IslandProp, parent: Node, spot: Transform3D) -> void:
	var plant_node := prop.scene.instantiate() as Node3D
	parent.add_child(plant_node)
	plant_node.global_transform = spot
	plant_node.rotate_y(randf() * TAU)
	plant_node.scale = Vector3.ONE * randf_range(prop.min_scale, prop.max_scale)


func pick_fitting_prop(point: Vector3, occupied: Array[Vector3], keep_clear: Array[Vector2]) -> IslandProp:
	var flat := Vector2(point.x, point.z)

	var large := freed_tree_props.duplicate()
	large.shuffle()
	for prop: IslandProp in large:
		if fits(prop, flat, occupied) and not is_near_any(flat, keep_clear, freed_tree_clearance):
			return prop

	var small := freed_small_props.duplicate()
	small.shuffle()
	for prop: IslandProp in small:
		if fits(prop, flat, occupied, freed_small_clearance):
			return prop

	return null


func fits(prop: IslandProp, flat: Vector2, occupied: Array[Vector3], large_clearance := -1.0) -> bool:
	for other in occupied:
		var required := maxf(prop.radius, other.z)
		if large_clearance >= 0.0 and other.z > large_clearance:
			required = large_clearance

		if flat.distance_squared_to(Vector2(other.x, other.y)) < required * required:
			return false

	return true


func is_near_any(flat: Vector2, points: Array[Vector2], distance: float) -> bool:
	for point in points:
		if flat.distance_to(point) < distance:
			return true

	return false
