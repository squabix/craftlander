class_name Item
extends Resource

signal scene_set_up
signal made_unique
signal triggered_event(event: ItemEvent)
# Item state signals
signal started_use
signal continued_use
signal ended_use

enum CooldownMode { DISABLED, START_USE, END_USE }
enum UseState { START_USE, CONTINUE_USE, END_USE }

@export var name := "":
	get:
		# Fallback to resource path if no name is set
		if name.is_empty():
			return resource_path
		return name
@export var max_quantity := 1
@export var icon: Texture2D
@export var consumable := false
@export var type := "Miscellaneous"

@export_group("Scene")
@export var scene: PackedScene
@export var visuals_scene_path := "Visuals" # Node path inside the scene containing visual meshes, particles, animations, etc.

@export_group("Cooldown")
@export var cooldown_mode := CooldownMode.DISABLED
@export var default_cooldown_length := 0.0

var max_uses := 1 # Maximum consecutive uses (frames)
var scene_instance: Node
var visuals: Node:
	get:
		if not is_instance_valid(visuals) and not is_scene_set_up:
			printerr(self, " has no visuals without setting up scene")
			return null
		return visuals
var current_use_state: UseState = UseState.END_USE
var is_unique := false:
	set(to):
		is_unique = to
		if to == true:
			made_unique.emit()
var is_scene_set_up := false
var update_delta := 0.0
var cooldown_start_time := -INF
var cooldown_length := default_cooldown_length
var root: Node
# Trackers for the frame update loop
var _attempted_use := false
var _used_this_update := false
var _updates_attempted_use := 0


func _to_string() -> String:
	return name + " Item"


## Halts execution using await until this resource has been made unique
func ensure_unique() -> void:
	if is_unique:
		return
	await made_unique


func equals(other_item: Item) -> bool:
	if other_item == null:
		return false
	return name == other_item.name


func find_in_array(array: Array) -> Item:
	for a in array:
		if a is Item and equals(a):
			return a
	return null


func start_cooldown(custom_length: float = 0.0) -> void:
	cooldown_start_time = Time.get_ticks_msec()
	cooldown_length = custom_length if custom_length > 0.0 else default_cooldown_length


func trigger_event(event: ItemEvent) -> void:
	if event == null:
		return
	event.item = self
	triggered_event.emit(event)


func update(delta: float) -> void:
	idle()
	update_delta = delta

	# Start Logic (first frame of use)
	if _used_this_update and current_use_state == UseState.END_USE:
		current_use_state = UseState.START_USE
		started_use.emit()

	# Continue Logic (multiple frames of use)
	elif _used_this_update and _updates_attempted_use > 0:
		current_use_state = UseState.CONTINUE_USE
		continued_use.emit()
		continue_use()

	# Termination Logic (first frame of no use)
	if current_use_state != UseState.END_USE and (reached_use_limit() or not _used_this_update):
		# Try starting cooldown
		if cooldown_mode == CooldownMode.END_USE:
			start_cooldown()

		end_use()

		current_use_state = UseState.END_USE
		ended_use.emit()

		# Reset counter
		_updates_attempted_use = 0
		_attempted_use = false

	# Increment counter if actively attempting use and haven't just ended
	if _attempted_use and current_use_state != UseState.END_USE:
		_updates_attempted_use += 1
	else:
		_updates_attempted_use = 0

	_used_this_update = false
	_attempted_use = false


func reached_use_limit() -> bool:
	return max_uses > 0 and _updates_attempted_use >= max_uses


func use() -> bool:
	_attempted_use = true

	# Fail if on cooldown
	if _updates_attempted_use == 0 and is_on_cooldown():
		return false

	# Fail if reached limit
	if reached_use_limit():
		return false

	# Use is successful
	_used_this_update = true
	if _updates_attempted_use == 0:
		if cooldown_mode == CooldownMode.START_USE:
			start_cooldown()
		start_use()

	return true


func instantiate(quantity: int = 1) -> ItemInstance:
	var instance := ItemInstance.new()
	instance.item = self
	instance.quantity = quantity
	return instance


func set_up_scene() -> void:
	if is_scene_set_up:
		return

	if not scene_instance:
		scene_instance = scene.instantiate()

	# Find visuals
	visuals = scene_instance.get_node_or_null(visuals_scene_path)
	if is_instance_valid(visuals):
		visuals.hide()

	is_scene_set_up = true
	scene_set_up.emit()


func duplicate_visuals() -> Node:
	if scene == null:
		printerr(self, " cannot get visuals duplicate from null scene")
		return null

	var temp_instance := scene.instantiate()
	var target_node := temp_instance.get_node_or_null(visuals_scene_path)
	var duplicate_node: Node = null

	if is_instance_valid(target_node):
		duplicate_node = target_node.duplicate()
	else:
		printerr(self, " failed to find visuals path for duplication: ", visuals_scene_path)

	temp_instance.queue_free()
	return duplicate_node


func add_scene(parent: Node) -> Node:
	if scene == null:
		printerr(name, " cannot instantiate null scene")
		return

	if not is_scene_set_up or scene_instance == null:
		is_scene_set_up = false
		Util.safe_free(scene_instance)
		scene_instance = scene.instantiate()
		parent.add_child(scene_instance)
		set_up_scene()
	else:
		parent.add_child(scene_instance)

	return scene_instance


func remove_scene() -> void:
	if not is_instance_valid(scene_instance):
		return
	Util.safe_free(scene_instance)
	clear_nodes()
	is_scene_set_up = false


func clear_nodes() -> void:
	scene_instance = null
	visuals = null


func is_on_cooldown() -> bool:
	return Time.get_ticks_msec() < cooldown_start_time + cooldown_length * 1000.0


func start_use() -> bool:
	return false


func continue_use() -> bool:
	return false


func end_use() -> bool:
	return false


func idle() -> void:
	pass
