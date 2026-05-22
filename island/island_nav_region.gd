extends NavigationRegion3D
class_name IslandNavRegion

@export var island_generator: HeightmapTerrainGenerator
@export var bake_on_ready := true

static var current: IslandNavRegion

func _ready() -> void:
	current = self
	if bake_on_ready:
		for i in 2: await get_tree().process_frame
		bake()

func bake() -> void:
	get_tree().paused = true
	bake_navigation_mesh(true)
	await bake_finished
	get_tree().paused = false
