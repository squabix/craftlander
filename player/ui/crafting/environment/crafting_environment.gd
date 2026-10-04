class_name CraftingEnvironment
extends SubViewportContainer

signal grid_changed
signal placed
signal emptied
signal crafted(item: Item)
signal craft_failed
signal started_craft_tweening
signal tweened_craft_merge
signal tweened_craft_showcase

const MAX_DRAG_DISTANCE := 1.0
const MAX_SLOT_DISTANCE := 1.0
const DRAG_SPEED := 1.0
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
@export_custom(PROPERTY_HINT_NONE, "suffix:Hz") var selection_wiggle_frequency := 8.0
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var selection_wiggle_intensity := 12.0

@export_subgroup("Craft Fail")
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var fail_wiggle_intensity := 15.0
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var fail_wiggle_duration := 0.24

@export_subgroup("Craft Success")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var success_merge_duration := 0.35
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var success_merge_stagger_delay_offset := 0.05
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var success_showcase_height := 0.6
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var success_showcase_pop_duration := 0.3
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var success_showcase_hang_duration := 0.3
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var success_drop_sink_depth := 1.5
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var success_drop_duration := 0.35

@export_group("Slot Fit", "slot_fit")
@export var slot_fit_regions: Array[Control]
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var slot_fit_size := 0.5
@export_range(0.0, 1.0) var slot_fit_speed := 0.3

@export_group("External Dependencies")
@export var inventory: Inventory
@export var selector: InventorySelector
@export var held_stack: HeldStack
@export var pause_interface: Control
@export var is_crafting := false:
	set(value):
		is_crafting = value
		if is_node_ready():
			update_viewport_size()
		if is_crafting:
			update_selection_visuals()
		else:
			reset_selection_visuals()

var slots_contents: Array[ItemVisualsContainer3D]
var selection_visuals: ItemVisualsContainer3D
var is_tweening_craft_result := false


func _ready() -> void:
	space.global_position = SPACE_POSITION

	reset_slots()

	if is_instance_valid(held_stack):
		held_stack.changed.connect(update_selection_visuals)
	if is_instance_valid(pause_interface):
		pause_interface.updated_pause.connect(func(_paused: bool): clear())

	update_selection_visuals.call_deferred()
	update_viewport_size()


func _process(_delta: float) -> void:
	if not is_crafting:
		return

	var mouse := get_mouse_position3d()
	cursor3d.global_position = mouse

	if is_instance_valid(selection_visuals):
		selection_visuals.global_position = selection_visuals.global_position.lerp(mouse, DRAG_SPEED)
		update_selection_scale()
		_wiggle_selection()

	if is_tweening_craft_result:
		return

	interpolate_slots_contents()

	var current_slot_index := get_current_slot()
	if Input.is_action_pressed("grid_place"):
		place(current_slot_index)
	elif Input.is_action_pressed("grid_remove"):
		empty(current_slot_index)


func _input(event: InputEvent) -> void:
	if not is_crafting or is_tweening_craft_result:
		return
	if event.is_action_pressed("craft"):
		craft()


func update_viewport_size() -> void:
	stretch = is_crafting
	if not is_crafting:
		sub_viewport.size = Vector2i.ONE


func reset_slots() -> void:
	slots_contents.clear()
	slots_contents.resize(grid.get_child_count())


func get_recipe_layout() -> Dictionary[Vector2i, Item]:
	var layout: Dictionary[Vector2i, Item] = { }
	var slots := grid.get_children()

	for i in range(slots_contents.size()):
		if not is_instance_valid(slots_contents[i]):
			continue

		var slot_node = slots[i] as Node3D
		if not slot_node:
			continue

		var layout_position := Vector2i(
			int((slot_node.global_position.x - SPACE_POSITION.x) / RECIPE_LAYOUT_SCALE),
			-int((slot_node.global_position.z - SPACE_POSITION.z) / RECIPE_LAYOUT_SCALE),
		)
		layout[layout_position] = slots_contents[i].get_item()
	return layout


func reset_selection_visuals() -> void:
	Util.safe_free(selection_visuals)
	selection_visuals = null


func update_selection_visuals() -> void:
	if is_tweening_craft_result:
		return

	if not is_crafting or not is_instance_valid(held_stack):
		reset_selection_visuals()
		return

	var new_instance := held_stack.instance
	if not is_instance_valid(new_instance) or new_instance.item == null:
		reset_selection_visuals()
		return

	if is_instance_valid(selection_visuals) and selection_visuals.get_item() == new_instance.item:
		return

	reset_selection_visuals()

	new_instance.item.set_up_scene()
	selection_visuals = spawn_item(new_instance.item, slot_fit_size)
	selection_visuals.fit_blend = get_slot_fit_target()


func update_selection_scale() -> void:
	if not is_instance_valid(selection_visuals):
		return

	selection_visuals.fit_blend = lerpf(selection_visuals.fit_blend, get_slot_fit_target(), slot_fit_speed)


func get_slot_fit_target() -> float:
	return 1.0 if is_mouse_over_slot_region() else 0.0


func is_mouse_over_slot_region() -> bool:
	var mouse := get_global_mouse_position()
	for region in slot_fit_regions:
		if is_instance_valid(region) and region.is_visible_in_tree() and region.get_global_rect().has_point(mouse):
			return true
	return false


func get_scaled_mouse_position2d() -> Vector2:
	var local_mouse := get_local_mouse_position()
	return Vector2(
		local_mouse.x / size.x * sub_viewport.size.x,
		local_mouse.y / size.y * sub_viewport.size.y,
	)


func get_mouse_position3d() -> Vector3:
	return Util.get_mouse_position_3d(
		camera,
		get_scaled_mouse_position2d(),
	)


func spawn_item(item: Item, fit_size := 0.0) -> ItemVisualsContainer3D:
	var visuals := ItemVisualsContainer3D.from_item(item)
	visuals.fit_size = fit_size
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


func move_item_to_grid_inventory() -> Item:
	var item := held_stack.take_one()
	if item == null:
		return null

	grid_inventory.add_item(item, 1)
	update_selection_visuals()
	return item


func remove_item_from_grid_inventory(item: Item) -> void:
	grid_inventory.remove_item(item, 1)

	var leftover := 0 if held_stack.try_add_one(item) else return_to_selected_slot(item)
	if leftover > 0:
		leftover = inventory.add_item(item, leftover)
	if leftover > 0:
		held_stack.drop_leftover(item, leftover)

	update_selection_visuals()
	grid_changed.emit()


func return_to_selected_slot(item: Item) -> int:
	if not is_instance_valid(selector) or not selector.enabled or selector.selected_index == -1:
		return 1

	var leftover := selector.inventory.merge_instance_into(selector.selected_index, item.instantiate(1))
	return 0 if leftover == null else leftover.quantity


func can_empty_slot(slot_index: int) -> bool:
	var old_visuals: ItemVisualsContainer3D = slots_contents[slot_index]
	if old_visuals == null:
		return true

	return inventory.has_room(old_visuals.get_item(), 1)


func place(slot_index: int) -> void:
	if is_tweening_craft_result or not is_instance_valid(selection_visuals) or slot_index == -1:
		return

	if slots_contents[slot_index] != null and slots_contents[slot_index].get_item().equals(selection_visuals.get_item()):
		return

	if not can_empty_slot(slot_index):
		return

	if held_stack.is_empty():
		reset_selection_visuals()
		return

	empty(slot_index)

	var visuals_to_place := selection_visuals
	selection_visuals = null

	if move_item_to_grid_inventory() == null:
		Util.safe_free(visuals_to_place)
		return

	visuals_to_place.fit_blend = 0.0
	slots_contents[slot_index] = visuals_to_place
	grid_changed.emit()
	update_selection_visuals.call_deferred()
	placed.emit()


func clear() -> void:
	for index in grid_inventory.get_occupied_indicies():
		var instance := grid_inventory.get_instance(index)
		var leftover := inventory.add_item(instance.item, instance.quantity)
		if leftover > 0:
			held_stack.drop_leftover(instance.item, leftover)

	grid_inventory.clear()

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
			SNAP_SPEED,
		)
		slot_visuals.rotation_degrees = slot_visuals.rotation_degrees.lerp(
			VISUALS_TILT,
			SNAP_SPEED,
		)


func empty(slot_index: int) -> void:
	if is_tweening_craft_result or slot_index == -1:
		return

	var old_visuals: ItemVisualsContainer3D = slots_contents[slot_index]
	if old_visuals == null or not can_empty_slot(slot_index):
		return

	var item_to_remove = old_visuals.get_item()

	slots_contents[slot_index] = null
	remove_item_from_grid_inventory(item_to_remove)

	tween_empty(old_visuals)
	emptied.emit()


func tween_empty(visuals: ItemVisualsContainer3D) -> void:
	var drop_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	drop_tween.tween_property(
		visuals,
		"global_position",
		visuals.global_position + Vector3.DOWN * success_drop_sink_depth,
		success_drop_duration,
	)
	drop_tween.tween_property(
		visuals,
		"scale",
		Vector3.ZERO,
		success_drop_duration,
	)

	drop_tween.finished.connect(
		func() -> void:
			Util.safe_free(visuals)
	)


func tween_craft_fail() -> void:
	is_tweening_craft_result = true

	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var step1_time := fail_wiggle_duration / 4.0
	var step2_time := fail_wiggle_duration / 2.0

	var turn := func(visual: Node3D, amount: float, delay: float) -> void:
		tween.tween_property(visual, ^"rotation_degrees", VISUALS_TILT + Vector3(0.0, amount, 0.0), step1_time).set_delay(delay)

	for visual in slots_contents:
		if not is_instance_valid(visual):
			continue

		turn.call(visual, +fail_wiggle_intensity, 0.0)
		turn.call(visual, -fail_wiggle_intensity, step1_time)
		turn.call(visual, 0.0, step1_time + step2_time)

	tween.tween_interval(fail_wiggle_duration)
	await tween.finished
	is_tweening_craft_result = false
	update_selection_visuals()


func emit_craft_particles(spawn_position: Vector3) -> void:
	if not is_instance_valid(craft_particles):
		return
	craft_particles.global_position = spawn_position
	craft_particles.restart()
	craft_particles.emitting = true


func tween_craft_success(item: Item) -> void:
	started_craft_tweening.emit()
	is_tweening_craft_result = true

	var visuals_to_animate: Array[ItemVisualsContainer3D] = slots_contents.filter(is_instance_valid)

	var craft_center := grid.global_position
	if not visuals_to_animate.is_empty():
		var position_sum := Vector3.ZERO
		for visual in visuals_to_animate:
			position_sum += visual.global_position
		craft_center = position_sum / visuals_to_animate.size()

	grid_inventory.clear()
	slots_contents.fill(null)
	grid_changed.emit()

	var merge_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var max_delay := 0.0
	var shuffled_indexes: Array = range(visuals_to_animate.size())
	shuffled_indexes.shuffle()
	for i in shuffled_indexes:
		var visual := visuals_to_animate[i]

		var delay: float = i * success_merge_stagger_delay_offset
		max_delay = max(max_delay, delay)

		merge_tween.tween_property(visual, ^"global_position", craft_center, success_merge_duration).set_delay(delay)
		merge_tween.tween_property(visual, ^"scale", Vector3.ZERO, success_merge_duration).set_delay(delay)

	merge_tween.tween_interval(max_delay + success_merge_duration)
	await merge_tween.finished
	tweened_craft_merge.emit()

	for visual in visuals_to_animate:
		Util.safe_free(visual)

	emit_craft_particles(craft_center)

	item.set_up_scene()
	var crafted_visuals := ItemVisualsContainer3D.from_item(item)
	item_origin.add_child(crafted_visuals)
	crafted_visuals.global_position = craft_center
	crafted_visuals.scale = Vector3.ZERO
	crafted_visuals.rotation_degrees = VISUALS_TILT

	var showcase_tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	showcase_tween.tween_property(crafted_visuals, ^"scale", Vector3.ONE * VISUALS_SCALE, success_showcase_pop_duration)
	showcase_tween.parallel().tween_property(crafted_visuals, ^"global_position", craft_center + Vector3.UP * success_showcase_height, success_showcase_pop_duration)

	craft_particles.emitting = true

	showcase_tween.tween_interval(success_showcase_hang_duration)

	showcase_tween.chain().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	showcase_tween.tween_property(crafted_visuals, ^"global_position", craft_center + Vector3.DOWN * success_drop_sink_depth, success_drop_duration)
	showcase_tween.parallel().tween_property(crafted_visuals, ^"scale", Vector3.ZERO, success_drop_duration)

	await showcase_tween.finished
	tweened_craft_showcase.emit()

	Util.safe_free(crafted_visuals)
	is_tweening_craft_result = false
	update_selection_visuals()


func craft() -> void:
	if is_tweening_craft_result:
		return

	var recipe := RecipeBook.get_recipe(get_recipe_layout())
	if recipe == null:
		tween_craft_fail()
		craft_failed.emit()
		return

	if not inventory.has_room(recipe.result.item, recipe.result.quantity):
		tween_craft_fail()
		craft_failed.emit()
		return

	await tween_craft_success(recipe.result.item)

	var leftover := inventory.add_item(
		recipe.result.item,
		recipe.result.quantity,
		false,
	)
	if leftover > 0:
		held_stack.drop_leftover(recipe.result.item, leftover)

	update_selection_visuals()

	grid_changed.emit()
	crafted.emit(recipe.result.item)
	EventBus.trigger(&"item_crafted", recipe.result.item)


func _wiggle_selection() -> void:
	if not is_instance_valid(selection_visuals):
		return
	var time := Time.get_ticks_msec() * selection_wiggle_frequency * 0.001
	var wiggle := sin(time) * selection_wiggle_intensity
	selection_visuals.rotation_degrees = VISUALS_TILT + Vector3.UP * wiggle
