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
@export var craft_particles: GPUParticles3D

@export_group("Tween Settings")

@export_subgroup("Selection Wiggle")
@export var selection_wiggle_speed := 8.0
@export var selection_wiggle_intensity := 12.0

@export_subgroup("Craft Fail")
@export var fail_wiggle_speed := 8.0
@export var fail_wiggle_intensity := 15.0
@export var fail_wiggle_duration := 0.24

@export_subgroup("Craft Success")
@export var success_merge_duration := 0.35
@export var success_merge_stagger_delay_offset := 0.05

@export var success_showcase_height := 0.6
@export var success_showcase_pop_duration := 0.3
@export var success_showcase_hang_duration := 0.3

@export var success_drop_sink_depth := 1.5
@export var success_drop_duration := 0.35

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

# Guard flag used to freeze all inputs and internal grid updates during animations
var is_tweening_craft_result := false

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
	# Do not auto-update selection visual arrangements while middle-animation running
	if is_tweening_craft_result:
		return
		
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
	if is_tweening_craft_result or not is_instance_valid(selection_visuals) or slot_index == -1:
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
		slot_visuals.rotation_degrees = slot_visuals.rotation_degrees.lerp(
			VISUALS_TILT,
			SNAP_SPEED
		)

func _process(_delta: float) -> void:
	if not is_crafting:
		return
	
	var mouse := get_mouse_position3d()
	cursor3d.global_position = mouse
	
	# Transform selection visuals via mouse position and wiggling
	if is_instance_valid(selection_visuals):
		selection_visuals.global_position = selection_visuals.global_position.lerp(mouse, DRAG_SPEED)
		_wiggle_selection()
	
	# If animating, suppress grid interpolation and grid input
	if is_tweening_craft_result:
		return
	
	interpolate_slots_contents()
	
	# Grid input
	var current_slot_index := get_current_slot()
	if Input.is_action_pressed("grid_place"):
		place(current_slot_index)
	elif Input.is_action_pressed("grid_remove"):
		empty(current_slot_index)

func _wiggle_selection() -> void:
	if not is_instance_valid(selection_visuals):
		return
	var time := Time.get_ticks_msec() * selection_wiggle_speed * 0.001
	var wiggle := sin(time) * selection_wiggle_intensity
	selection_visuals.rotation_degrees = VISUALS_TILT + Vector3.UP * wiggle

func empty(slot_index: int) -> void:
	if is_tweening_craft_result or slot_index == -1:
		return
	
	var old_visuals: ItemVisualsContainer3D = slots_contents[slot_index]
	if old_visuals == null:
		return
	
	var item_to_remove = old_visuals.get_item()
	
	slots_contents[slot_index] = null 
	remove_item_from_grid_inventory(item_to_remove)
	
	tween_empty(old_visuals)

func tween_empty(visuals: ItemVisualsContainer3D) -> void:
	var drop_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	drop_tween.tween_property(
		visuals, 
		"global_position", 
		visuals.global_position + Vector3.DOWN * success_drop_sink_depth, 
		success_drop_duration
	)
	drop_tween.tween_property(
		visuals, 
		"scale", 
		Vector3.ZERO,
		success_drop_duration
	)
	
	drop_tween.finished.connect(func() -> void:
		Util.safe_free(visuals)
	)

func tween_craft_fail() -> void:
	is_tweening_craft_result = true
	
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var step1_time := fail_wiggle_duration / 4.0
	var step2_time := fail_wiggle_duration / 2.0
	var step3_time := fail_wiggle_duration / 4.0
	
	var turn := func(visual: Node3D, amount: float, delay: float) -> void:
		tween.tween_property(visual, "rotation_degrees", VISUALS_TILT + Vector3(0.0, amount, 0.0), step1_time).set_delay(delay)
	
	for visual in slots_contents:
		if not is_instance_valid(visual):
			continue
		
		turn.call(visual, +fail_wiggle_intensity, 0.0) # Turn left
		turn.call(visual, -fail_wiggle_intensity, step1_time) # Turn right
		turn.call(visual, 0.0, step1_time + step2_time) # Return to normal tilt
	
	await tween.finished
	is_tweening_craft_result = false

func emit_craft_particles(spawn_position: Vector3) -> void:
	if not is_instance_valid(craft_particles):
		return
	craft_particles.global_position = spawn_position
	craft_particles.restart()
	craft_particles.emitting = true

func tween_craft_success(item: Item) -> void:
	is_tweening_craft_result = true
	
	var visuals_to_animate: Array[ItemVisualsContainer3D] = slots_contents.filter(is_instance_valid)
	
	var craft_center := grid.global_position
	if not visuals_to_animate.is_empty():
		var position_sum := Vector3.ZERO
		for visual in visuals_to_animate:
			position_sum += visual.global_position
		craft_center = position_sum / visuals_to_animate.size()
	
	grid_inventory.clear()
	grid_changed.emit()
	
	var merge_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Merge visuals with staggered delay
	var max_delay := 0.0
	var shuffled_indexes: Array = range(visuals_to_animate.size())
	shuffled_indexes.shuffle()
	for i in shuffled_indexes:
		var visual := visuals_to_animate[i]
		
		# Calculate staggered delay
		var delay: float = i * success_merge_stagger_delay_offset
		max_delay = max(max_delay, delay)
		
		merge_tween.tween_property(visual, "global_position", craft_center, success_merge_duration).set_delay(delay)
		merge_tween.tween_property(visual, "scale", Vector3.ZERO, success_merge_duration).set_delay(delay)
		
	# Wait until the last staggered item completes its slide
	merge_tween.tween_interval(max_delay + success_merge_duration)
	await merge_tween.finished
	
	# Free visual resources once compressed completely
	for visual in visuals_to_animate:
		Util.safe_free(visual)
	
	# Emit particles from center
	emit_craft_particles(craft_center)
		
	# Set up visuals for newly crafted results at the center
	item.set_up_scene()
	var crafted_visuals := ItemVisualsContainer3D.from_item(item)
	item_origin.add_child(crafted_visuals)
	crafted_visuals.global_position = craft_center
	crafted_visuals.scale = Vector3.ZERO
	crafted_visuals.rotation_degrees = VISUALS_TILT
	
	# Showcase the new item
	var showcase_tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	showcase_tween.tween_property(crafted_visuals, "scale", Vector3.ONE * VISUALS_SCALE, success_showcase_pop_duration)
	showcase_tween.parallel().tween_property(crafted_visuals, "global_position", craft_center + Vector3.UP * success_showcase_height, success_showcase_pop_duration)
	
	craft_particles.emitting = true
	
	# Let the new item hang in the air
	showcase_tween.tween_interval(success_showcase_hang_duration)
	
	# Drop the item down below out of sight into the player inventory
	showcase_tween.chain().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	showcase_tween.tween_property(crafted_visuals, "global_position", craft_center + Vector3.DOWN * success_drop_sink_depth, success_drop_duration)
	showcase_tween.parallel().tween_property(crafted_visuals, "scale", Vector3.ZERO, success_drop_duration)
	
	await showcase_tween.finished
	
	Util.safe_free(crafted_visuals)
	is_tweening_craft_result = false

func craft() -> void:
	var recipe := RecipeBook.get_recipe(get_recipe_layout())
	if recipe == null:
		tween_craft_fail()
		return
	
	if not inventory_selector.inventory.has_room(recipe.result.item, recipe.result.quantity):
		tween_craft_fail()
		return 
	
	# Begin animation sequence & lock user viewport interaction inputs
	await tween_craft_success(recipe.result.item)
	
	# Give item to player inventory
	inventory_selector.inventory.add_item(
		recipe.result.item,
		recipe.result.quantity,
		false
	)
	
	update_selection_visuals()

func _input(event: InputEvent) -> void:
	if not is_crafting or is_tweening_craft_result:
		return
	if event.is_action_pressed("craft"): 
		craft()
