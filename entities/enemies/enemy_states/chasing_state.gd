extends State

@export var nav_guide: NavEntityGuide3D
@export var sight: RadialSight3D
@export var min_approach_distance := 1.5

@onready var anim_player: ItemAnimationPlayer = %AnimationPlayer
@onready var inventory: Inventory = %Inventory

func enter() -> void:
	anim_player.update_item(inventory.get_item(0))

func update(_delta: float) -> void:
	if sight.does_see_target():
		nav_guide.set_target(sight.target_position)
		nav_guide.face_target()
		if nav_guide.nav.distance_to_target() > min_approach_distance:
			nav_guide.entity.move_forward()
		else:
			attack()
	else:
		transition_to("Wandering")

func attack() -> void:
	if inventory.get_item(0).is_on_cooldown():
		return
	inventory.get_item(0).use()
