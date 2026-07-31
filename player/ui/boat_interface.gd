class_name BoatInterface
extends Control

@export var island_option_container: Control
@export var pause_interface: PauseInterface
@export var boat_upgrader: BoatUpgrader
@export var sail_button: Button

var selected_option: IslandOption
var current_boat: Boat


func _ready() -> void:
	hide()
	var options: Array[IslandOption]
	options.assign(island_option_container.get_children())
	for option in options:
		option.select_button.toggled.connect(_on_option_toggled.bind(option))
		option.hide()

	sail_button.pressed.connect(load_selected_island)


func _process(_delta: float) -> void:
	if is_instance_valid(current_boat) and pause_interface.pressed_pause():
		close()


func open(boat: Boat) -> void:
	if not is_instance_valid(boat):
		Util.node_error("%s cannot open with invalid boat: ", self, boat)
		return
	sail_button.disabled = true
	set_pause(true)
	current_boat = boat
	boat_upgrader.boat = boat
	reload_options()


func reload_options() -> void:
	if not is_instance_valid(island_option_container):
		Util.node_error("%s cannot reload options inside invalid container: %s", self, island_option_container)
		return
	
	for i in min(current_boat.level + 1, island_option_container.get_child_count()):
		island_option_container.get_child(i).reload()


func close() -> void:
	set_pause(false)
	if is_instance_valid(island_option_container):
		for option in island_option_container.get_children():
			option.hide()
	current_boat = null


func set_pause(to: bool) -> void:
	visible = to
	get_tree().paused = to
	pause_interface.can_update_pause = not to
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if to else Input.MOUSE_MODE_CAPTURED


func load_selected_island() -> void:
	if not is_instance_valid(selected_option):
		return
	Main.root.load_level(selected_option.island_index)


func _on_option_toggled(to: bool, option: IslandOption) -> void:
	if to == false:
		selected_option = null
		sail_button.disabled = true
		return

	selected_option = option
	sail_button.disabled = false
