class_name BoatProgressPanel
extends VBoxContainer

const TITLE_FORMAT := "Boat Upgrade: Level %s"
const TITLE_MAXED := "Boat Fully Upgraded"

@export var boat_upgrader: BoatUpgrader
@export var player_inventory: Inventory
@export var title_label: Label
@export var requirement_display_container: Node

var requirement_displays: Array[ItemDisplay]


func _ready() -> void:
	requirement_displays.assign(requirement_display_container.get_children())
	player_inventory.instance_changed.connect(refresh.unbind(1))
	visibility_changed.connect(refresh)
	boat_upgrader.upgraded.connect(refresh.unbind(1))


func refresh() -> void:
	if not is_visible_in_tree():
		return

	var next_level: int = Main.loaded_save.boat_level + 1
	var requirement: Inventory = boat_upgrader.requirements.get(next_level)
	if requirement == null:
		show_maxed()
		return

	title_label.text = TITLE_FORMAT % next_level
	for display in requirement_displays:
		display.inventory = requirement
		display.fraction_number = player_inventory.get_item_quantity(display.get_item())


func show_maxed() -> void:
	title_label.text = TITLE_MAXED
	for display in requirement_displays:
		display.inventory = null
