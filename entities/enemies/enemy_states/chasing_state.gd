extends State

@export var nav_guide: NavEntityGuide3D
@export var sight: RadialSight3D
@export var min_approach_distance := 1.5

@export var can_lose_target := true
@export var lose_target_state := ""

@onready var inventory: Inventory = %Inventory
@onready var item_holder: ItemHolder3D = %ItemHolder3D

func update(_delta: float) -> void:
	if can_lose_target and (sight != null and not sight.does_see_target()):
		transition_to(lose_target_state)
		return
	
	nav_guide.set_target(sight.target_position)
	nav_guide.face_target()
	
	if nav_guide.nav.distance_to_target() > min_approach_distance:
		if nav_guide.nav.is_target_reachable():
			nav_guide.entity.move_forward()
	else:
		item_holder.use_item()
