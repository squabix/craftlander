extends AnimationTree
class_name ItemAnimationTree

@export var item_animations: Array[ItemAnimations] = []
@export var inventory_selector: InventorySelector

@export_group("Defaults")
@export var default_start_anim := ""
@export var default_continue_anim := ""
@export var default_end_anim := ""

@export_group("Tree Parameter Paths")
@export var playback_path := "parameters/ItemStateMachine/playback"
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
var state_machine: AnimationNodeStateMachine

func _ready() -> void:
	default_animations()
	initialize_playback()
	disable_item_blend()
	
	# Update when inventory selector selects new instance
	if is_instance_valid(inventory_selector):
		inventory_selector.selected_instance_changed.connect(
			func(_instance: ItemInstance) -> void:
				update_item(inventory_selector.get_current_item())
		)
		update_item(inventory_selector.get_current_item())
	
	active = true

func initialize_playback() -> void:
	playback = get(playback_path) as AnimationNodeStateMachinePlayback
	if playback == null:
		printerr("%s found null playback at path: ", playback_path)
		return
	
	playback.state_finished.connect(_on_state_finished)
	state_machine = tree_root.get_node(playback_path.replace("parameters/", "").replace("/playback", "")) as AnimationNodeStateMachine

func _on_state_finished(state_name: String) -> void:
	
	# Disable current item blend when item state machine finishes
	if state_name == end_use_state:
		disable_item_blend()
	
	# Play end use
	elif current_item != null and current_item.current_use_state == Item.UseState.END_USE:
		play_end()

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
		printerr("%s's null playback cannot travel to state %s " % [self, state])
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
	if tree_root == null:
		printerr("%s's tree root is null" % self)
		return
		
	if state_machine == null:
		printerr("%s's state machine is null" % self)
		return
		
	var state_anim_map: Dictionary[String, String] = get_state_anim_map()
	
	for state_node_name in state_anim_map:
		if not state_machine.has_node(state_node_name):
			printerr("%s's state machine does not contain a node named: %s" % [self, state_node_name])
			continue
		
		var anim_node := state_machine.get_node(state_node_name) as AnimationNodeAnimation
		if anim_node == null:
			printerr("State machine node '", state_node_name, "' is invalid in %s" % self)
			continue
		
		anim_node.animation = state_anim_map[state_node_name]
