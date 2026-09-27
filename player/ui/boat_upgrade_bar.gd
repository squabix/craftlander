class_name BoatUpgradeBar
extends InterpolatedBar

@export var boat_upgrader: BoatUpgrader
@export var player_inventory: Inventory


func _ready() -> void:
	super()
	player_inventory.instance_changed.connect(refresh.unbind(1))


func refresh() -> void:
	var requirement: Inventory = boat_upgrader.requirements.get(Main.loaded_save.boat_level + 1)
	if requirement == null:
		hide()
		return

	show()
	var required_quantities := requirement.get_item_quantities()
	var required_total := 0
	var held_total := 0
	for item in required_quantities:
		var required: int = required_quantities[item]
		required_total += required
		held_total += min(player_inventory.get_item_quantity(item), required)

	max_value = required_total
	target_value = held_total
