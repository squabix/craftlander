extends Item
class_name HarvestingTool

@export var harvest_animation: String = "harvest"

var harvest_ray: HitRay3D
var animation_player: AnimationPlayer

func set_up_scene() -> void:
	if scene_instance == null:
		return
	super()
	harvest_ray = scene_instance.get_node("HarvestRay")
	animation_player = visuals.get_node("AnimationPlayer")
	harvest_ray.damage.source = root

func start_use() -> bool:
	if is_instance_valid(animation_player):
		animation_player.stop()
		animation_player.play(harvest_animation)
	if harvest_ray.hit():
		pass # Hit successful
	return true
