extends SubViewportContainer
class_name CraftingEnvironment

signal grid_changed

const MAX_DRAG_DISTANCE := 1.0
const MAX_SLOT_DISTANCE := 1.0
const DRAG_SPEED := 0.2
const VISUALS_SCALE := 0.5
const SNAP_SPEED := 0.3
const SPACE_POSITION := -Vector3.ONE * 1000.0
const VISUALS_TILT := Vector3(0.0, -45.0, 0.0)

const RECIPE_LAYOUT_SCALE := 1.0

@export var sub_viewport: SubViewport
@export var space: Node3D
@export var item_origin: Node3D
@export var camera: Camera3D
@export var grid: Node3D
@export var grid_inventory: Inventory
@export var cursor3d: RayCast3D

@export_group("External Dependencies")
@export var inventory_selector: InventorySelector
@export var pause_interface: Control

@export var is_crafting := false:
	set(value):
		is_crafting = value
		if is_crafting:
			update_selection_visuals()
		else:
			reset_selection_visuals()

var slots_contents: Array[ItemVisualsContainer3D]
var selection_visuals: ItemVisualsContainer3D

func reset_slots() -> void:
	slots_contents.clear()
	slots_contents.resize(grid.get_child_count())

func _ready() -> void:
	space.global_position = SPACE_POSITION
	
	reset_slots()
	
	# Connect signals
	if is_instance_valid(inventory_selector):
		inventory_selector.selected_new_index.connect(update_selection_visuals.unbind(1))
	if is_instance_valid(pause_interface):
		pause_interface.updated_pause.connect(func(_paused: bool): clear())
	
	update_selection_visuals.call_deferred()

func get_recipe_layout() -> Dictionary[Vector2i, Item]:
	var layout: Dictionary[Vector2i, Item] = {}
	var slots := grid.get_children()
	
	for i in range(slots_contents.size()):
		if not is_instance_valid(slots_contents[i]):
			continue
			
		var slot_node = slots[i] as Node3D
		if not slot_node:
			continue
			
		var layout_position := Vector2i(
			int((slot_node.global_position.x - SPACE_POSITION.x) / RECIPE_LAYOUT_SCALE),
			-int((slot_node.global_position.z - SPACE_POSITION.z) / RECIPE_LAYOUT_SCALE)
		)
		layout[layout_position] = slots_contents[i].get_item()
	return layout

func reset_selection_visuals() -> void:
	Util.safe_free(selection_visuals)
	selection_visuals = null

func update_selection_visuals() -> void:
	if not is_crafting or not is_instance_valid(inventory_selector):
		reset_selection_visuals()
		return
	
	var new_instance := inventory_selector.get_current_instance()
	if not is_instance_valid(new_instance) or new_instance.item == null:
		reset_selection_visuals()
		return
	
	if is_instance_valid(selection_visuals) and selection_visuals.get_item() == new_instance.item:
		return
		
	reset_selection_visuals()
	
	# Set held visuals to current held item
	new_instance.item.set_up_scene()
	selection_visuals = spawn_item(new_instance.item)

func get_scaled_mouse_position2d() -> Vector2:
	var local_mouse := get_local_mouse_position()
	return Vector2(
		local_mouse.x / size.x * sub_viewport.size.x,
		local_mouse.y / size.y * sub_viewport.size.y
	)

func get_mouse_position3d() -> Vector3:
	return Util.get_mouse_position_3d(
		camera,
		get_scaled_mouse_position2d()
	)

func spawn_item(item: Item) -> ItemVisualsContainer3D:
	var visuals := ItemVisualsContainer3D.from_item(item)
	item_origin.add_child(visuals)
	visuals.scale *= VISUALS_SCALE
	visuals.rotation_degrees = VISUALS_TILT
	visuals.global_position = get_mouse_position3d()
	return visuals

func get_current_slot() -> int:
	if not cursor3d.is_colliding():
		return -1
	var overlap: Area3D = cursor3d.get_collider()
	
	var slots := grid.get_children()
	for i in range(slots.size()):
		if slots[i] == overlap or slots[i].global_position.is_equal_approx(overlap.global_position):
			return i
			
	return -1

func move_item_to_grid_inventory(item: Item) -> void:
	inventory_selector.inventory.give_item(item, 1, grid_inventory)
	update_selection_visuals()
	grid_changed.emit()

func remove_item_from_grid_inventory(item: Item) -> void:
	grid_inventory.give_item(item, 1, inventory_selector.inventory)
	update_selection_visuals()
	grid_changed.emit()

func place(slot_index: int) -> void:
	if not is_instance_valid(selection_visuals):
		return
	
	if slot_index == -1:
		return
	
	if slots_contents[slot_index] != null and slots_contents[slot_index].get_item() == selection_visuals.get_item():
		return
	
	empty(slot_index)
	
	var visuals_to_place := selection_visuals
	selection_visuals = null
	
	slots_contents[slot_index] = visuals_to_place
	move_item_to_grid_inventory(visuals_to_place.get_item())
	update_selection_visuals.call_deferred()

func clear() -> void:
	grid_inventory.give_everything(inventory_selector.inventory)
	for i in range(slots_contents.size()):
		Util.safe_free(slots_contents[i])
		slots_contents[i] = null
	grid_changed.emit()

func interpolate_slots_contents() -> void:
	var slots := grid.get_children()
	for i in range(slots_contents.size()):
		var slot_visuals := slots_contents[i]
		if not is_instance_valid(slot_visuals):
			continue
		
		slot_visuals.global_position = slot_visuals.global_position.lerp(
			slots[i].global_position,
			SNAP_SPEED
		)

func _process(_delta: float) -> void:
	if not is_crafting:
		return
	
	interpolate_slots_contents()
	
	var current_slot_index := get_current_slot()
	if Input.is_action_pressed("grid_place"):
		place(current_slot_index)
	elif Input.is_action_pressed("grid_remove"):
		empty(current_slot_index)
	
	var mouse := get_mouse_position3d()
	cursor3d.global_position = mouse
	if is_instance_valid(selection_visuals):
		selection_visuals.global_position = selection_visuals.global_position.lerp(mouse, DRAG_SPEED)

func empty(slot_index: int) -> void:
	if slot_index == -1:
		return
	var old_visuals: ItemVisualsContainer3D = slots_contents[slot_index]
	if old_visuals == null:
		return
	
	var item_to_remove = old_visuals.get_item()
	Util.safe_free(old_visuals)
	slots_contents[slot_index] = null 
	remove_item_from_grid_inventory(item_to_remove)

func craft() -> void:
	var recipe := RecipeBook.get_recipe(get_recipe_layout())
	if recipe == null:
		return
	
	var remainder := inventory_selector.inventory.add_item(
		recipe.result.item,
		recipe.result.quantity,
		true
	)
	if remainder > 0:
		return 
	
	grid_inventory.clear()
	clear()

func _input(event: InputEvent) -> void:
	if not is_crafting:
		return
	if event.is_action_pressed("craft"): 
		craft()
