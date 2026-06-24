extends AnimationTree
class_name ItemAnimationTree

@export var item_animations: Array[ItemAnimations] = []
@export var inventory_selector: InventorySelector

@export_group("Defaults")
@export var default_start_anim := ""
@export var default_continue_anim := ""
@export var default_end_anim := ""

@export_group("Tree Parameter Paths")
@export var state_machine_path := "parameters/ItemStateMachine"
@export var item_state_path := "parameters/ItemUseTransition/current_state"
@export var item_blend_path := "parameters/ItemBlend/blend_amount"

@export_group("State Machine States")
@export var start_use_state := "start_use"
@export var continue_use_state := "continue_use"
@export var end_use_state := "end_use"

var current_item: Item
var start_anim := ""
var continue_anim := ""
var end_anim := ""
var playback: AnimationNodeStateMachinePlayback

func _ready() -> void:
	default_animations()
	initialize_playback()
	disable_item_blend()
	
	if is_instance_valid(inventory_selector):
		inventory_selector.updated.connect(update_to_selection)
	
	active = true

func initialize_playback() -> void:
	playback = get(state_machine_path + "/playback")
	if playback != null:
		playback.state_finished.connect(_on_state_finished)

func _on_state_finished(state_name: String) -> void:
	
	# Disable current item blend when item state machine finishes
	if state_name == end_use_state:
		disable_item_blend()
	
	# Play end use
	elif current_item != null and current_item.current_use_state == Item.UseState.END_USE:
		play_end()

func update_to_selection() -> void:
	update_item(inventory_selector.get_current_item())

func default_animations() -> void:
	start_anim = default_start_anim
	continue_anim = default_continue_anim
	end_anim = default_end_anim

func update_item(new_item: Item) -> void:
	reset_current_item()
	
	if new_item == null:
		return
	if new_item != null:
		await new_item.ensure_unique()
	
	load_animations(get_animations(new_item))
	update_tree_animations()
	
	# Connect new item's signals (only start signal)
	new_item.started_use.connect(play_start)
	
	current_item = new_item

func reset_current_item() -> void:
	if current_item == null:
		return
	current_item.started_use.disconnect(play_start)
	current_item = null

func get_animations(item: Item) -> ItemAnimations:
	for item_anims in item_animations:
		var key := item.find_in_array(item_anims.items)
		if key != null:
			return item_anims
	return null


func load_animations(anims: ItemAnimations) -> void:
	if anims == null:
		default_animations()
		return
	start_anim = anims.start_anim if has_animation(anims.start_anim) else ""
	continue_anim = anims.continue_anim if has_animation(anims.continue_anim) else ""
	end_anim = anims.end_anim if has_animation(anims.end_anim) else ""

func get_player() -> AnimationPlayer:
	return get_node(anim_player)

func enable_item_blend() -> void:
	set(item_blend_path, 1.0)

func disable_item_blend() -> void:
	set(item_blend_path, 0.0)

func play_start() -> void:
	enable_item_blend()
	if start_anim.is_empty():
		return
	play_state(start_use_state)

func play_state(state: String) -> void:
	if playback == null:
		printerr("Null playback cannot travel to state ", state)
		return
	playback.start(state)

func get_current_item_anim() -> String:
	return get(item_state_path)

func play_end() -> void:
	play_state(end_use_state)
	if end_anim.is_empty():
		disable_item_blend()

func get_state_anim_map() -> Dictionary[String, String]:
	return {
		start_use_state: start_anim,
		continue_use_state: continue_anim,
		end_use_state: end_anim
	}

func update_tree_animations() -> void:
	var state_anim_map: Dictionary[String, String] = get_state_anim_map()
	for state in state_anim_map:
		set(state_machine_path + "/" + state + "/animation", state_anim_map[state])
