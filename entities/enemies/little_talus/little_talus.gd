extends Entity3D

@export var anim_tree: AnimationTree
@export var anim_player: AnimationPlayer
@export var health: Health
@export var culling_controller: CullingController3D

func _ready() -> void:
	if is_instance_valid(health):
		health.died.connect(_on_died)

	# Wait two frames then update visibility range
	await get_tree().process_frame
	await get_tree().process_frame
	culling_controller.update_visibility_range()

func _process(_delta: float) -> void:
	# Interpolate between animations by velocity
	var velocity_length := Util.vec3to2(velocity, Util.VECTOR3Y).length()
	if anim_tree:
		anim_tree.set(
			"parameters/RunBlendSpace/blend_position",
			velocity_length / move_mode.max_speed.x
		)

func _on_died() -> void:
	set_physics_process(false)
	if is_instance_valid(anim_tree):
		anim_tree.active = false
	if is_instance_valid(anim_player):
		anim_player.active = false
	Util.safe_free(self)
