class_name BoatUpgrader
extends VBoxContainer

@export var requirements: Dictionary[int, Inventory]
@export var requirement_display_container: Node
@export var default_requirement: Inventory
@export var upgrade_button: Button
@export var player_inventory: Inventory
@export var boat_interface: BoatInterface

var boat: Boat:
	set(to):
		boat = to
		update()
var current_upgrade_level := 0
var requirement_displays: Array[ItemDisplay]
var current_requirement: Inventory

func _ready() -> void:
	requirement_displays.assign(requirement_display_container.get_children())
	upgrade_button.pressed.connect(upgrade)

func update() -> void:
	if not is_instance_valid(boat):
		printerr("%s cannot display requirements for invalid boat")
		return
	
	current_upgrade_level = boat.level + 1
	current_requirement = requirements.get(current_upgrade_level, default_requirement)
	for display in requirement_displays:
		display.inventory = current_requirement
	
	var can_upgrade := current_requirement.is_inside(player_inventory)
	upgrade_button.disabled = not can_upgrade

func upgrade() -> void:
	if not current_requirement.is_inside(player_inventory):
		return
	player_inventory.subtract_inventory(current_requirement)
	Main.loaded_save.boat_level = current_upgrade_level
	boat_interface.current_boat = boat_interface.current_boat.make_current()
	Main.root.save_current_game()
	boat_interface.close()
	print("Upgraded boat to %s" % current_upgrade_level)
