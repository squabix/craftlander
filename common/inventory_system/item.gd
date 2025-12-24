extends Resource
class_name Item

signal scene_set_up

@export var scene: PackedScene
@export var name := "":
	get:
		if name.is_empty():
			return resource_name
		return name
@export var max_quantity := 1
@export var icon: Texture2D
@export var consumable := false
@export var visuals_scene_path := "Visuals"

var max_uses := 1
var scene_instance: Node
var visuals: Node

var _attempted_use := false
var _used_this_update := false
var _updates_attempted_use := 0
var _ended_use := true

var update_delta := 0.0
var root: Node

func update(delta: float) -> void:
	idle()
	update_delta = delta
	if _used_this_update:
		_ended_use = false
		if _updates_attempted_use != 0:
			continue_use()
	
	var reached_max_uses := _updates_attempted_use == max_uses and max_uses > 0
	if not _ended_use and (reached_max_uses or not _used_this_update):
		end_use()
		_ended_use = true
		_updates_attempted_use = 0
	
	if not _attempted_use:
		_updates_attempted_use = 0
	else:
		_updates_attempted_use += 1
	
	_used_this_update = false
	_attempted_use = false

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
	if is_instance_valid(scene_instance):
		scene_instance.queue_free()
		
	scene_instance = scene.instantiate()
	parent.add_child(scene_instance)
	set_up_scene()
	return scene_instance

func use() -> bool:
	_attempted_use = true
	if max_uses > 0 and _updates_attempted_use > max_uses:
		return false
	_used_this_update = true
	if _updates_attempted_use == 0:
		return start_use()
	return false

func start_use() -> bool:
	return false

func continue_use() -> bool:
	return false

func end_use() -> bool:
	return false

func idle() -> void:
	pass
