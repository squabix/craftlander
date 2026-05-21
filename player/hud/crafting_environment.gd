extends SubViewportContainer
class_name CraftingEnvironment

const MAX_DRAG_DISTANCE := 1.0
const MAX_SLOT_DISTANCE := 1.0
const DRAG_SPEED := 0.2
const PICKUP_SCALE := 0.5
const SNAP_SPEED := 0.3
const SPACE_POSITION := -Vector3.ONE * 1000.0
const PICKUP_TILT := Vector3(0.0, -45.0, 0.0)

const RECIPE_LAYOUT_SCALE := 1.0

@export var subviewport: SubViewport
@export var space: Node3D
@export var item_origin: Node3D
@export var camera: Camera3D
@export var grid: Node3D
@export var grid_inventory: Inventory
@export var cursor3d: RayCast3D

@export_group("External Dependencies")
@export var inventory_holder_link: InventoryHolderLink
@export var pause_interface: Control

var slots_contents: Dictionary[Vector3, ItemPickup3D]

var is_crafting := false
var held_pickup: ItemPickup3D

func reset_slots() -> void:
	for slot_node in grid.get_children():
		if not slot_node is Node3D:
			continue
		slots_contents[slot_node.global_position] = null

func _ready() -> void:
	space.global_position = SPACE_POSITION
	
	reset_slots()
	
	# Connect signals
	if is_instance_valid(inventory_holder_link):
		inventory_holder_link.changed.connect(update_held_pickup)
	if is_instance_valid(pause_interface):
		pause_interface.updated_pause.connect(clear)
	
	update_held_pickup.call_deferred()

func get_recipe_layout() -> Dictionary[Vector2i, Item]:
	var layout: Dictionary[Vector2i, Item]
	for slot in slots_contents:
		if not is_instance_valid(slots_contents[slot]):
			continue
		var layout_position := Vector2i(
			int((slot.x - SPACE_POSITION.x) / RECIPE_LAYOUT_SCALE),
			-int((slot.z - SPACE_POSITION.z) / RECIPE_LAYOUT_SCALE)
		)
		layout[layout_position] = slots_contents[slot].item
	return layout

func reset_held_pickup() -> void:
	Util.safe_free(held_pickup)
	held_pickup = null

func update_held_pickup() -> void:
	reset_held_pickup()
	
	if not is_instance_valid(inventory_holder_link):
		return
	
	var new_instance := inventory_holder_link.get_current_instance()
	if not is_instance_valid(new_instance):
		return
	
	# Set held pickup to current held item
	held_pickup = spawn_item(new_instance.item)

func get_scaled_mouse_position2d() -> Vector2:
	var local_mouse := get_local_mouse_position()
	return Vector2(
		local_mouse.x / size.x * subviewport.size.x,
		local_mouse.y / size.y * subviewport.size.y
	)

func get_mouse_position3d() -> Vector3:
	return Util.get_mouse_position_3d(
		camera,
		get_scaled_mouse_position2d()
	)

func spawn_item(item: Item) -> ItemPickup3D:
	var pickup := ItemPickup3D.from_item(item)
	item_origin.add_child(pickup)
	pickup.scale *= PICKUP_SCALE
	pickup.rotation_degrees = PICKUP_TILT
	return pickup

func get_current_slot() -> Variant:
	if not cursor3d.is_colliding():
		return null
	var overlap: Area3D = cursor3d.get_collider()
	return overlap.global_position

func move_item_to_grid_inventory(item: Item) -> void:
	inventory_holder_link.inventory.give_item(item, 1, grid_inventory)

func remove_item_from_grid_inventory(item: Item) -> void:
	grid_inventory.give_item(item, 1, inventory_holder_link.inventory)

func place_current() -> void:
	
	# Has no current to place
	if not is_instance_valid(held_pickup):
		return
	
	# Not hovering over any slot
	var slot: Variant = get_current_slot()
	if slot == null:
		return
	
	empty_slot(slot)
	slots_contents[slot] = held_pickup
	move_item_to_grid_inventory(held_pickup.item)
	held_pickup = null
	update_held_pickup.call_deferred()

func clear() -> void:
	grid_inventory.give_everything(inventory_holder_link.inventory)
	for slot in slots_contents:
		Util.safe_free(slots_contents[slot])
		slots_contents[slot] = null

func interpolate_slots_contents() -> void:
	for slot in slots_contents:
		var slot_pickup := slots_contents[slot]
		if not is_instance_valid(slot_pickup):
			continue
		slot_pickup.global_position = slot_pickup.global_position.lerp(
			slot,
			SNAP_SPEED
		)

func _process(_delta: float) -> void:
	if not is_crafting:
		return
	
	interpolate_slots_contents()
	
	# Empty current slot
	if Input.is_action_pressed("use_secondary") and not Input.is_action_pressed("use_primary"):
		empty_slot(get_current_slot())
	
	# Reposition cursor 3d and held pickup to mouse
	var mouse := get_mouse_position3d()
	cursor3d.global_position = mouse
	if is_instance_valid(held_pickup):
		held_pickup.global_position = held_pickup.global_position.lerp(mouse, DRAG_SPEED)

func empty_slot(slot: Variant) -> void:
	if slot == null:
		return
	
	var old_pickup: ItemPickup3D = slots_contents[slot]
	if old_pickup == null:
		return
	
	Util.safe_free(old_pickup)
	remove_item_from_grid_inventory(old_pickup.item)

func craft() -> void:
	var recipe := RecipeBook.get_recipe(get_recipe_layout())
	if recipe == null:
		return
	
	var remainder := inventory_holder_link.inventory.add_item(
		recipe.result.item,
		recipe.result.quantity,
		true
	)
	if remainder > 0:
		return # Inventory too full for crafted items
	
	grid_inventory.clear()
	clear()

func _input(event: InputEvent) -> void:
	if not is_crafting:
		return
	if event.is_action_pressed("use_primary"): place_current()
	elif event.is_action_pressed("craft"): craft()
