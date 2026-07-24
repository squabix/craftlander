class_name Boat
extends EntityVehicle3D

const BOAT_SCENE_PATH_FORMAT := "res://boat/boat%s.tscn"

@export var level := 0

@export_group("Components")
@export var state_machine: StateMachine
@export var driver_seat: Seat3D
@export var interactable: Interactable3D

var dock_position: Vector3


static func instantiate(boat_level: int) -> Boat:
	var path := BOAT_SCENE_PATH_FORMAT % boat_level
	if not ResourceLoader.exists(path):
		printerr("Cannot load nonexistant next boat level %s" % [path])
		return null
	
	var resource := load(path)
	if not resource is PackedScene:
		printerr("Cannot instantiate non-scene path %s" % path)
		return null
	
	var instance := (resource as PackedScene).instantiate()
	if not instance is Boat:
		printerr("Cannot instantiate non-boat node %s at %s" % [instance, path])
		return null
	
	return instance


func _ready() -> void:
	interactable.interacted_with.connect(open_boat_interface)
	set_physics_process(false)


func open_boat_interface(interact_source: Node) -> void:
	if not interact_source is Player:
		printerr("Invalid interact source %s cannot open boat interface" % interact_source)
		return

	var boat_interface: BoatInterface = interact_source.boat_interface
	if not is_instance_valid(boat_interface):
		printerr("%s cannot load invalid boat interface %s" % [interact_source, boat_interface])
		return

	boat_interface.open(self)


func get_current_state() -> State:
	if state_machine == null:
		return null
	return state_machine.current


func make_current() -> Boat:
	var next_boat := instantiate(Main.loaded_save.boat_level)
	if not is_instance_valid(next_boat):
		printerr("%s cannot become current without valid next boat")
		return null
	get_parent().add_child(next_boat)
	next_boat.global_transform = self.global_transform
	next_boat.state_machine.enter_state(&"Docked")
	queue_free()
	return next_boat

# PILOTING

#@export_group("Piloting")
#@export_custom(PROPERTY_HINT_NONE, "suffix:°/s") var max_turn_speed := 0.0
#@export_range(0.0, 1.0, 0.01, "suffix:°/s²") var turn_acceleration := 0.1

#var turn_velocity := 0.0 # The current rolling interpolation speed
#var turn_amount := 0.0 # Stores the input direction for the physics frame
#var forward_speed := 0.0

#func _process(delta: float) -> void:
	## Boat turns poorly when stationary, faster when moving
	#forward_speed = velocity.dot(-transform.basis.z)
	#var speed_factor := clampf(abs(forward_speed) / 5.0, 0.0, 1.0)
#
	## Interpolate the turn velocity toward our target input
	#var target_turn_velocity = turn_amount * max_turn_speed * speed_factor
	#turn_velocity = lerpf(turn_velocity, target_turn_velocity, turn_acceleration)
#
	#rotation_degrees.y += turn_velocity * delta
#
	#turn_amount = 0.0

#func turn(amount: float) -> void:
	#turn_amount = amount
