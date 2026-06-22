extends Item
class_name HarvestingTool

@export var harvest_animation: String = "harvest"

var harvest_ray: HitRay3D
var anim_player: AnimationPlayer

func clear_nodes() -> void:
	super()
	harvest_ray = null
	anim_player = null

func set_up_scene() -> void:
	if scene_instance == null:
		return
	super()
	harvest_ray = scene_instance.get_node("HarvestRay")
	harvest_ray.damage.source = root

func start_use() -> bool:
	if is_instance_valid(anim_player) and anim_player.has_animation(harvest_animation):
		anim_player.stop()
		anim_player.play(harvest_animation)
	
	if harvest_ray != null:
		var result := harvest_ray.hit()
		if result != null:
			pass # Successful hit
	return true
