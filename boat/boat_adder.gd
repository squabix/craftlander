class_name BoatAdder
extends Spawner3D

var dock_position: Vector3
var boat: Boat


func create_instance() -> Node3D:
	return PlayerBoat.instantiate(Main.loaded_save.boat_level if &"boat_level" in Main.loaded_save else 0)


func initialize_instance(instance: Node3D) -> void:
	if not is_instance_valid(instance):
		return
	boat = instance
	boat.dock_position = self.dock_position
	boat.look_at(boat.dock_position)
