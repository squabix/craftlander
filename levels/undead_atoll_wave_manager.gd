extends WaveSpawner3D

@export var player: Player
@export var ghost_docking_managers: Array[DockingManager]

var started := false


func _ready() -> void:
	EventBus.subscribe(&"treasure_chest_opened", start)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("drop") and not started:
		EventBus.trigger(&"treasure_chest_opened")


func start(start_index := 0) -> void:
	if started:
		return
	started = true
	for manager in ghost_docking_managers:
		manager.add_boat()
		var boat := manager.boat as GhostBoat
		disable_spawner(boat.spawner)
		boat.docked.connect(enable_spawner.bind(boat.spawner), CONNECT_ONE_SHOT)

	super(start_index)


func _initialize_instance(instance: Node3D) -> void:
	super(instance)
	var sight := Util.find_child_of_class(instance, &"RadialSight3D") as RadialSight3D
	sight.set_target(player)
