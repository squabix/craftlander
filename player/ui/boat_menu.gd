class_name BoatMenu
extends Menu

signal opened

const LEVEL_FORMAT := "Boat Level %d / %d"
const SAIL_TEXT := "Set Sail"
const CURRENT_TEXT := "You Are Here"
const LOCKED_TEXT := "Locked"

@export var island_carousel: IslandCarousel
@export var pause_menu: PauseMenu
@export var boat_upgrader: BoatUpgrader
@export var sail_button: Button
@export var level_label: Label

var current_boat: Boat


func _ready() -> void:
	hide()
	super()
	sail_button.pressed.connect(load_selected_island)
	island_carousel.page_changed.connect(_on_page_changed)


func open_boat(boat: Boat) -> void:
	if not is_instance_valid(boat):
		Util.node_error("%s cannot open with invalid boat: %s", self, boat)
		return
	sail_button.disabled = true
	set_pause(true)
	current_boat = boat
	boat_upgrader.boat = boat
	reload_options()
	auto_focus()
	opened.emit()


func reload_options() -> void:
	if not is_instance_valid(island_carousel):
		Util.node_error("%s cannot reload options inside invalid carousel: %s", self, island_carousel)
		return

	level_label.text = LEVEL_FORMAT % [current_boat.level, boat_upgrader.max_level]
	island_carousel.reload(current_boat.level)
	update_sail_button()


func back() -> void:
	if Menu.lock_frame():
		return
	if not is_instance_valid(current_boat):
		return

	set_pause(false)
	current_boat = null
	backed_out.emit()


func auto_focus() -> void:
	if not boat_upgrader.upgrade_button.disabled:
		boat_upgrader.upgrade_button.grab_focus()
		return

	if not sail_button.disabled:
		sail_button.grab_focus()
		return

	super()


func set_pause(to: bool) -> void:
	visible = to
	get_tree().paused = to
	pause_menu.can_update_pause = not to
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if to else Input.MOUSE_MODE_CAPTURED


func load_selected_island() -> void:
	var option := island_carousel.get_current_option()
	if not is_instance_valid(option) or not option.is_sailable():
		return
	Main.root.load_level(option.island_resource.index)


func update_sail_button() -> void:
	var option := island_carousel.get_current_option()
	if not is_instance_valid(option):
		sail_button.disabled = true
		return

	match option.status:
		IslandOption.Status.AVAILABLE:
			sail_button.text = SAIL_TEXT
		IslandOption.Status.CURRENT:
			sail_button.text = CURRENT_TEXT
		IslandOption.Status.LOCKED:
			sail_button.text = LOCKED_TEXT
	sail_button.disabled = not option.is_sailable()


func _on_page_changed(_index: int, _page: Control) -> void:
	update_sail_button()
