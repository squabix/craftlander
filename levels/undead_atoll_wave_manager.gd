extends WaveSpawner3D

@export var ghost_docking_managers: Array[DockingManager]

func _ready() -> void:
	EventBus.subscribe(&"treasure_chest_opened", start)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("drop"):
		EventBus.trigger(&"treasure_chest_opened")

func start(start_index := 0) -> void:
	print("Starting Undead Atoll waves")
	for manager in ghost_docking_managers:
		manager.add_boat()
		var boat := manager.boat as GhostBoat
		disable_spawner(boat.spawner)
		boat.docked.connect(enable_spawner.bind(boat.spawner), CONNECT_ONE_SHOT)
	
	super(start_index)
