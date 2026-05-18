extends DestructableResource

@onready var bee_spawners: Array[Spawner3D] = [
	$BeeSpawner1,
	$BeeSpawner2,
	$BeeSpawner3,
	$BeeSpawner4,
	$BeeSpawner5
]

func _ready() -> void:
	super()
	health.died.connect(
		func() -> void:
			for spawner in bee_spawners:
				spawner.spawn()
	)
