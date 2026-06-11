extends Resource
class_name GameWorld

const GRAVITY_3D_RATIO := 1.0
const TIME_SCALE := 1.0

static var _current: GameWorld

@export var gravity_strength := 17.0
@export var gravity_direction := Vector3.DOWN

var tree: SceneTree
var default_parent_3d: Node

static func get_current() -> GameWorld:
	if _current:
		return _current
	return GameWorld.new()

func spawn3d(scene: PackedScene, at: Vector3, parent: Node=default_parent_3d) -> Node3D:
	if scene == null:
		return
	if parent == null:
		return
	
	var instance: Node = scene.instantiate()
	
	if not instance is Node3D:
		return
	
	parent.add_child(instance)
	instance.global_position = at
	
	return instance

func get_gravity3d(multiplier: float=1.0) -> Vector3:
	return gravity_direction * gravity_strength * multiplier * GRAVITY_3D_RATIO

func get_gravity2d(multiplier: float=1.0) -> Vector2:
	return -Util.vec3to2(gravity_direction, Util.VECTOR3Z) * gravity_strength * multiplier
