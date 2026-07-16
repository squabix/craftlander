extends InventoryAnimationTree

const DEFAULT_MOVE_BLEND_SPACE_PATH := "DefaultMoveBlendSpace"
const MOVE_TRANSITION_PATH := "MoveTransition"

const DEFAULT_MOVE_BLEND_POSITION_PATH := "parameters/%s/blend_position" % DEFAULT_MOVE_BLEND_SPACE_PATH
const MOVE_TRANSITION_REQUEST_PATH := "parameters/%s/transition_request" % MOVE_TRANSITION_PATH

const IDLE_ANIM := &"idle"
const WALK_ANIM := &"walk"
const SPRINT_ANIM := &"sprint"

const DEFAULT_TRANSITION_REQUEST := &"default"
const SWIM_TRANSITION_REQUEST := &"swim"
const MIDAIR_TRANSITION_REQUEST := &"midair"

@export var player: Player
@export var walking_move_mode: MoveMode
@export var sprinting_move_mode: MoveMode

var default_move_blend_space: AnimationNodeBlendSpace1D


func _ready() -> void:
	super()
	if tree_root == null:
		return

	default_move_blend_space = tree_root.get_node(DEFAULT_MOVE_BLEND_SPACE_PATH) as AnimationNodeBlendSpace1D

	if default_move_blend_space == null:
		printerr("%s could not find default move blend space in the tree root" % self)
		return

	var blend_positions := get_anim_blend_positions()

	# Set up overall min and max bounds
	default_move_blend_space.min_space = blend_positions.values().min()
	default_move_blend_space.max_space = blend_positions.values().max()

	# Position nodes based on animation names
	for i in default_move_blend_space.get_blend_point_count():
		var anim_node := default_move_blend_space.get_blend_point_node(i) as AnimationNodeAnimation
		if anim_node == null:
			continue
		var anim_name := StringName(anim_node.animation.to_lower())
		default_move_blend_space.set_blend_point_position(i, blend_positions.get(anim_name, 0.0))


func _process(_delta: float) -> void:
	if player == null:
		return

	var move_state := get_move_state()
	set_move_transition_request(move_state)

	if move_state == DEFAULT_TRANSITION_REQUEST:
		var speed := player.get_planar_speed()
		set_default_move_blend_position(speed)


func set_move_transition_request(to: String) -> void:
	set(MOVE_TRANSITION_REQUEST_PATH, to)


func set_default_move_blend_position(to: float) -> void:
	set(DEFAULT_MOVE_BLEND_POSITION_PATH, to)


func get_anim_blend_positions() -> Dictionary[StringName, float]:
	return {
		IDLE_ANIM: 0.0,
		WALK_ANIM: walking_move_mode.max_speed.x,
		SPRINT_ANIM: sprinting_move_mode.max_speed.x,
	}


func get_move_state() -> StringName:
	if player.is_in_water:
		return SWIM_TRANSITION_REQUEST
	if not player.is_on_floor():
		return MIDAIR_TRANSITION_REQUEST
	return DEFAULT_TRANSITION_REQUEST
