extends Item
class_name HarvestingTool

# TODO: Add "visuals" node to item scenes

var harvest_ray: HitRay3D

func set_up_scene() -> void:
	if scene_instance == null:
		return
	super()
	harvest_ray = scene_instance.get_node("HarvestRay")

func start_use() -> bool:
	print("Attempted hit")
	if harvest_ray.hit():
		print("Hit")
	return true
