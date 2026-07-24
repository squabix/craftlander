extends Node3D
class_name BoatAdder

signal added_boat

const BOAT_SCENE_PATH_FORMAT := "res://boat/boat%s.tscn"

var dock_position: Vector3
var boat: Boat

func add() -> Boat:
	print("Adding boat (position is %s)" % dock_position)
	boat = Boat.instantiate(Main.loaded_save.boat_level if &"boat_level" in Main.loaded_save else 0)
	if not is_instance_valid(boat):
		return null
	get_parent().add_child(boat)
	boat.global_transform = self.global_transform
	boat.dock_position = self.dock_position
	boat.look_at(boat.dock_position)
	added_boat.emit.call_deferred()
	return boat
