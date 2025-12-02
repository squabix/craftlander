extends Item
class_name HarvestingTool

# TODO: Add "visuals" node to item scenes

@export var efficiency: int

#func set_up_scene() -> void:
	#if scene_instance:
		#visuals = scene_instance.get_node("Visuals")
		#print("visuals")

func start_use() -> bool:
	print("Harvest")
	return true
