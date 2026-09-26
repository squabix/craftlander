class_name GhostWaveSpawner
extends WaveSpawner3D

@export var player: Player
@export var melee_coordinator: GhostMeleeCoordinator


func arrive(manager: DockingManager) -> GhostBoat:
	manager.add_boat()
	var boat := manager.boat as GhostBoat
	if not is_instance_valid(boat):
		Util.node_error("%s cannot arrive without a ghost boat from %s", self, manager)
		return null
	disable_spawner(boat.spawner)
	boat.docked.connect(enable_spawner.bind(boat.spawner), CONNECT_ONE_SHOT)
	return boat


func _initialize_instance(instance: Node3D) -> void:
	super(instance)
	var entity := instance as Entity3D
	if is_instance_valid(entity):
		var traits := Util.find_child_of_class(entity, &"GhostTraits") as GhostTraits
		if is_instance_valid(traits):
			traits.ghostify(melee_coordinator)
			traits.play_spawn_in()
		else:
			Util.node_error("%s cannot ghostify %s without a GhostTraits node", self, entity)
		entity.add_to_group(&"enemies")
		EntityPopulator.report_death_on_exit(entity)
	var sight := Util.find_child_of_class(instance, &"RadialSight3D") as RadialSight3D
	if is_instance_valid(sight):
		sight.set_target(player)
