class_name PlayerBoat
extends Boat

const BOAT_SCENE_PATH_FORMAT := "res://boat/player_boat/boat%s.tscn"

@export var level := 0
@export var interactable: Interactable3D


static func instantiate(boat_level: int) -> PlayerBoat:
	var path := BOAT_SCENE_PATH_FORMAT % boat_level
	if not ResourceLoader.exists(path):
		push_error("Cannot load nonexistant next boat level %s" % [path])
		return null
	
	var resource := load(path)
	if not resource is PackedScene:
		push_error("Cannot instantiate non-scene path %s" % path)
		return null
	
	var instance := (resource as PackedScene).instantiate()
	if not instance is Boat:
		Util.node_error("Cannot instantiate non-boat node %s at %s", instance, path)
		return null
	
	return instance


func _ready() -> void:
	interactable.interacted_with.connect(open_boat_menu)
	super()


func open_boat_menu(interact_source: Node) -> void:
	if not interact_source is Player:
		Util.node_error("Invalid interact source %s cannot open boat interface", interact_source)
		return

	var boat_menu: BoatMenu = interact_source.boat_menu
	if not is_instance_valid(boat_menu):
		Util.node_error("%s cannot load invalid boat interface %s", interact_source, boat_menu)
		return

	boat_menu.open_boat(self)


func make_current() -> Boat:
	var next_boat := instantiate(Main.loaded_save.boat_level)
	if not is_instance_valid(next_boat):
		Util.node_error("%s cannot become current without valid next boat", self)
		return null
	get_parent().add_child(next_boat)
	next_boat.global_transform = self.global_transform
	next_boat.state_machine.enter_state(&"Docked")
	queue_free()
	return next_boat
