class_name Enemy3D
extends Entity3D

@export var anim_tree: AnimationTree
@export var anim_player: AnimationPlayer
@export var health: Health
@export var culling_controller: CullingController3D
@export var attack_ray: HitRay3D

@export_group("Locomotion Animation", "locomotion")
@export var locomotion_blend_parameter := &"parameters/RunBlendSpace/blend_position"

var animate_locomotion := true


func _ready() -> void:
	super()
	if is_instance_valid(health):
		health.died.connect(_on_died)
	if is_instance_valid(attack_ray) and attack_ray.damage:
		attack_ray.damage.source = self

	# Wait two frames so held items exist before the visibility range is measured
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(culling_controller):
		culling_controller.update_visibility_range()


func _process(_delta: float) -> void:
	if animate_locomotion and is_instance_valid(anim_tree):
		anim_tree.set(locomotion_blend_parameter, get_planar_speed() / move_mode.max_speed.x)


func _on_died() -> void:
	set_physics_process(false)
	if is_instance_valid(anim_tree):
		anim_tree.active = false
	if is_instance_valid(anim_player):
		anim_player.active = false
	Util.safe_free(self)
