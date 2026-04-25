extends AnimationTree
class_name ItemAnimationTree

@export var item_animations: Array[ItemAnimations] = []

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

var item: Item
var start_anim := ""
var continue_anim := ""
var end_anim := ""
var playback: AnimationNodeStateMachinePlayback

func _ready() -> void:
	default()
	
	playback = get(state_machine_path + "/playback")
	if playback != null:
		
		# Disable item blend when item state machine finishes
		playback.state_finished.connect(
			func(state_name: String) -> void:
				if state_name == end_use_state:
					disable_item_blend()
				elif item != null and item.current_use_state == Item.UseState.END_USE:
					play_end()
		)
	disable_item_blend()
	active = true 

func default() -> void:
	start_anim = default_start_anim
	continue_anim = default_continue_anim
	end_anim = default_end_anim
	_assign_nodes_to_tree()

func update_item(new_item: Item) -> void:
	
	# Wait until item is unique
	if not new_item.is_unique:
		await new_item.made_unique
	
	# Disconnect old item's signals
	if item != null:
		item.started_use.disconnect(play_start)
		item = null
	
	var anims: ItemAnimations = null
	
	# Find new item animations
	for item_anims in item_animations:
		var key = new_item.find_in_array(item_anims.items)
		if key != null:
			anims = item_anims
			break
	
	# Update to new animations
	if anims != null:
		item = new_item
		
		# Validate animations exist in the AnimationPlayer
		start_anim = anims.start_anim if has_animation(anims.start_anim) else ""
		continue_anim = anims.continue_anim if has_animation(anims.continue_anim) else ""
		end_anim = anims.end_anim if has_animation(anims.end_anim) else ""
		
		_assign_nodes_to_tree()
	
	# Default if new animations are null
	else:
		default()
	
	# Connect new item's signals
	if item != null:
		item.started_use.connect(play_start)

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

func _assign_nodes_to_tree() -> void:
	var state_anim_map: Dictionary[String, String] = {
		start_use_state: start_anim,
		continue_use_state: continue_anim,
		end_use_state: end_anim
	}
	for state in state_anim_map:
		set(state_machine_path + "/" + state + "/animation", state_anim_map[state])
