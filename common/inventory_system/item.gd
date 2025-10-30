extends Resource
class_name Item

@export var name: String
@export var max_quantity: int = 1
@export var icon: Texture2D
@export var consumable: bool

var max_uses: int = 1
var scene: PackedScene
var scene_instance: Node

var _attempted_use: bool = false
var _used_this_update: bool = false
var _updates_attempted_use: int = 0
var _ended_use: bool = true

var update_delta: float = 0.0

func update(delta: float) -> void:
	idle()
	update_delta = delta
	if _used_this_update:
		_ended_use = false
		#if _updates_attempted_use == 0:
			#start_use()
		if _updates_attempted_use != 0:
			continue_use()
	
	var reached_max_uses: bool = _updates_attempted_use == max_uses and max_uses > 0
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
	var instance: ItemInstance = ItemInstance.new()
	instance.item = self
	instance.quantity = quantity
	return instance

func instantiate_scene() -> Node:
	if scene == null:
		return
	if is_instance_valid(scene_instance):
		scene_instance.queue_free()
	scene_instance = scene.instantiate()
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

func _to_string() -> String:
	return name
