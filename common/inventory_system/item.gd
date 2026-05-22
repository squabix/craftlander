extends Resource
class_name Item

signal scene_set_up
signal made_unique
signal triggered_event(event: ItemEvent)

signal started_use
signal continued_use
signal ended_use

enum CooldownMode {DISABLED, START_USE, END_USE}
enum UseState {START_USE, CONTINUE_USE, END_USE}

@export var scene: PackedScene
@export var name := "":
	get:
		if name.is_empty():
			return resource_path
		return name
@export var max_quantity := 1
@export var icon: Texture2D
@export var consumable := false
@export var visuals_scene_path := "Visuals"
@export_group("Cooldown")
@export var cooldown_mode := CooldownMode.DISABLED
@export var default_cooldown_length := 0.0

var max_uses := 1
var scene_instance: Node
var visuals: Node

var current_use_state: UseState = UseState.END_USE

var _attempted_use := false
var _used_this_update := false
var _updates_attempted_use := 0
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

static func imitate(item_name: String) -> Item:
	var imitation := Item.new()
	imitation.name = item_name
	return imitation

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
	
	# 1. Start Logic (First frame of use)
	if _used_this_update and current_use_state == UseState.END_USE:
		current_use_state = UseState.START_USE
		started_use.emit()

	# 2. Continue Logic (Multiple frames of use)
	elif _used_this_update and _updates_attempted_use > 0:
		current_use_state = UseState.CONTINUE_USE
		continued_use.emit()
		continue_use()

	# 3. Termination Logic (First frame not using)
	if current_use_state != UseState.END_USE:
		if reached_use_limit() or not _used_this_update:
			if cooldown_mode == CooldownMode.END_USE:
				start_cooldown()
			
			end_use()
			
			current_use_state = UseState.END_USE
			ended_use.emit()
			
			# Reset counter
			_updates_attempted_use = 0
			_attempted_use = false 

	# Increment counter if actively holding button and haven't just ended
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

func get_instance(quantity: int=1) -> ItemInstance:
	var instance := ItemInstance.new()
	instance.item = self
	instance.quantity = quantity
	return instance

func set_up_scene() -> void:
	if not scene_instance:
		printerr(name, " cannot set up scene without scene instance")
		return
	visuals = scene_instance.get_node(visuals_scene_path)
	if not is_instance_valid(visuals):
		printerr(name, " could not find visuals")
	if visuals != null:
		visuals.hide()
	is_scene_set_up = true
	scene_set_up.emit()

func get_visuals_duplicate() -> Node:
	if scene == null:
		printerr(name, " cannot get visuals duplicate from null scene")
		return
	return scene.instantiate().get_node(visuals_scene_path).duplicate()

func add_scene(parent: Node) -> Node:
	if scene == null:
		printerr(name, " cannot instantiate null scene")
		return
	Util.safe_free(scene_instance)
		
	scene_instance = scene.instantiate()
	parent.add_child(scene_instance)
	set_up_scene()
	return scene_instance

func remove_scene() -> void:
	if scene_instance == null:
		return
	Util.safe_free(scene_instance)
	clear_nodes()

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

func _to_string() -> String:
	return name + " " + str(scene)
