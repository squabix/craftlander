extends Node

const HOTBAR_FIRST := 0
const HOTBAR_LAST := 9
const BACKPACK_FIRST := 10
const BACKPACK_LAST := 39

@export var inventory: Inventory
@export var held_stack: HeldStack
@export var held_item_label: Label
@export var pause_interface: PauseMenu
@export var slot_containers: Array[Container]
@export var crafting_environment: CraftingEnvironment

@export_group("Selectors")
@export var hover_inventory_selector: InventorySelector
@export var hold_inventory_selector: InventorySelector

func _ready() -> void:
	pause_interface.updated_pause.connect(update_selection_mode)

	for container in slot_containers:
		for child in container.get_children():
			if child is ItemDisplay:
				child.clicked.connect(click_slot)

	update_selection_mode(false)

func _process(_delta: float) -> void:
	if not pause_interface.is_paused:
		return

	var display := get_focused_display()
	if display == null:
		return

	if Input.is_action_just_pressed(&"inventory_primary"):
		click_slot(display.index, false, false)
	elif Input.is_action_just_pressed(&"inventory_secondary"):
		click_slot(display.index, true, false)
	elif Input.is_action_just_pressed(&"inventory_quick_move"):
		click_slot(display.index, false, true)

func click_slot(index: int, secondary: bool, quick: bool) -> void:
	if not pause_interface.is_paused:
		return
	if is_instance_valid(crafting_environment) and crafting_environment.is_tweening_craft_result:
		return

	if quick:
		quick_move_slot(index)
	elif secondary:
		held_stack.secondary_click(inventory, index)
	else:
		held_stack.click(inventory, index)

func quick_move_slot(index: int) -> void:
	if index <= HOTBAR_LAST:
		inventory.quick_move(index, BACKPACK_FIRST, BACKPACK_LAST)
	else:
		inventory.quick_move(index, HOTBAR_FIRST, HOTBAR_LAST)

func get_focused_display() -> ItemDisplay:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null:
		return null

	var display := focused.get_parent() as ItemDisplay
	if display == null or focused != display.select_button:
		return null
	if display.get_parent() not in slot_containers:
		return null

	return display

func update_selection_mode(paused_mode: bool) -> void:
	hold_inventory_selector.enabled = not paused_mode
	hover_inventory_selector.enabled = paused_mode
	held_item_label.visible = not paused_mode
