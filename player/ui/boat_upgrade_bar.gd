class_name BoatUpgradeBar
extends InterpolatedBar

const READY_MESSAGE := "Boat upgrade ready! Follow the yellow marker on your compass to return to your boat."

@export var boat_upgrader: BoatUpgrader
@export var player_inventory: Inventory
@export var container: Control
@export var full_fill_style: StyleBox

var normal_fill_style: StyleBox

var _was_full := false


func _ready() -> void:
	super()
	normal_fill_style = get_theme_stylebox(&"fill")
	player_inventory.instance_changed.connect(refresh.unbind(1))
	boat_upgrader.upgraded.connect(refresh.unbind(1))
	for child in player_inventory.get_children():
		if child is NodeSaver:
			child.finished_load.connect(refresh.bind(false))
	refresh.call_deferred(false)


func refresh(can_notify := true) -> void:
	var requirement: Inventory = boat_upgrader.requirements.get(Main.loaded_save.boat_level + 1)
	if requirement == null:
		_was_full = false
		set_shown(false)
		return

	set_shown(true)
	var required_quantities := requirement.get_item_quantities()
	var required_total := 0
	var held_total := 0
	for item in required_quantities:
		var required: int = required_quantities[item]
		required_total += required
		held_total += min(player_inventory.get_item_quantity(item), required)

	max_value = required_total
	target_value = held_total
	var is_full := held_total >= required_total
	add_theme_stylebox_override(&"fill", full_fill_style if is_full else normal_fill_style)

	if is_full and not _was_full and can_notify and not Main.trailer_mode:
		HintToast.display(READY_MESSAGE)
	_was_full = is_full


func set_shown(to: bool) -> void:
	if is_instance_valid(container):
		container.visible = to
	visible = to
