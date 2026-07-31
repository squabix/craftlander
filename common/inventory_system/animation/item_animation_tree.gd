class_name ItemAnimationTree
extends AnimationTree

@export var item_animations: Array[ItemAnimations] = []

@export_group("Defaults")
@export var default_start_anim := &""
@export var default_continue_anim := &""
@export var default_end_anim := &""

@export_group("Tree Parameter Paths")
@export var playback_path := "parameters/ItemStateMachine/playback"
@export var item_state_path := "parameters/ItemUseTransition/current_state"
@export var item_blend_path := "parameters/ItemBlend/blend_amount"

@export_group("State Machine States")
@export var start_use_state := &"start_use"
@export var continue_use_state := &"continue_use"
@export var end_use_state := &"end_use"

var current_item: Item

var start_anim := &""
var continue_anim := &""
var end_anim := &""

var playback: AnimationNodeStateMachinePlayback
var animation_state_machine: AnimationNodeStateMachine


func _ready() -> void:
	default_animations()
	initialize_playback()
	disable_item_blend()

	active = true


func initialize_playback() -> void:
	playback = get(playback_path) as AnimationNodeStateMachinePlayback
	if playback == null:
		push_error("%s found null playback at path: %s" %[self, playback_path])
		return

	playback.state_finished.connect(_on_state_finished)
	animation_state_machine = tree_root.get_node(playback_path.replace("parameters/", "").replace("/playback", "")) as AnimationNodeStateMachine


func default_animations() -> void:
	start_anim = default_start_anim
	continue_anim = default_continue_anim
	end_anim = default_end_anim


func update_item(new_item: Item) -> void:
	reset_current_item()

	if new_item == null:
		return

	load_animations(get_animations(new_item))
	update_tree_animations()

	await new_item.ensure_unique()

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

	start_anim = _get_valid_animation(anims.start_anim)
	continue_anim = _get_valid_animation(anims.continue_anim)
	end_anim = _get_valid_animation(anims.end_anim)


func get_player() -> AnimationPlayer:
	return get_node(anim_player)


func enable_item_blend() -> void:
	set(item_blend_path, 1.0)


func disable_item_blend() -> void:
	set(item_blend_path, 0.0)


func play_start() -> void:
	if start_anim.is_empty():
		play_continue()
		return
	enable_item_blend()
	play_state(start_use_state)


func play_continue() -> void:
	if continue_anim.is_empty():
		play_end()
		return
	enable_item_blend()
	play_state(continue_use_state)


func play_end() -> void:
	if end_anim.is_empty():
		disable_item_blend()
		return
	enable_item_blend()
	play_state(end_use_state)


func play_state(state: StringName) -> void:
	if playback == null:
		push_error("%s's null playback cannot travel to state: %s" % [self, state])
		return
	playback.start(state)


func get_current_item_anim() -> StringName:
	return get(item_state_path)


func get_state_anim_map() -> Dictionary[StringName, StringName]:
	return {
		start_use_state: start_anim,
		continue_use_state: continue_anim,
		end_use_state: end_anim,
	}


func update_tree_animations() -> void:
	if tree_root == null:
		push_error("%s's tree root is null" % self)
		return

	if animation_state_machine == null:
		push_error("%s's state machine is null" % self)
		return

	var state_anim_map := get_state_anim_map()

	for state_node_name in state_anim_map:
		if not animation_state_machine.has_node(state_node_name):
			push_error("%s's state machine does not contain a node named: %s" % [self, state_node_name])
			continue

		var anim_node := animation_state_machine.get_node(state_node_name) as AnimationNodeAnimation
		if anim_node == null:
			push_error("State machine node '%s' is invalid in %s" % [state_node_name, self])
			continue

		var anim_name: StringName = state_anim_map[state_node_name]
		
		# Only assign if animation is valid and exists
		if not anim_name.is_empty() and has_animation(anim_name):
			anim_node.animation = anim_name


func _on_state_finished(state_name: StringName) -> void:
	# Disable current item blend when item state machine finishes
	if state_name == end_use_state:
		disable_item_blend()

	# Play end use
	elif current_item != null and current_item.current_use_state == Item.UseState.END_USE:
		play_end()


func _get_valid_animation(anim: StringName) -> StringName:
	return anim if has_animation(anim) else &""
