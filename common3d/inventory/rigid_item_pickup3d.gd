extends RigidBody3D
class_name RigidItemPickup3D

@export var item_pickup_interactable: ItemPickup3D
@export var hurtbox: Hurtbox3D

static func from_item(item: Item, scene: PackedScene) -> RigidItemPickup3D:
	if item == null:
		return
	var scene_instance := scene.instantiate() as RigidItemPickup3D
	if scene_instance == null:
		return
	scene_instance.item_pickup_interactable.item = item
	return scene_instance

func _ready() -> void:
	freeze = true
	item_pickup_interactable.auto_generate_collision = false
	item_pickup_interactable.picked_up.connect(Util.safe_free.bind(self))
	
	# Generate the collision shapes directly onto this RigidBody3D 
	var collision_shapes := item_pickup_interactable.generate_all_collision(self)
	
	# Duplicate collision shapes to hurtbox
	if hurtbox:
		for collision_shape in collision_shapes:
			var hurtbox_collision_duplicate: CollisionShape3D = collision_shape.duplicate()
			hurtbox.add_child(hurtbox_collision_duplicate)
			hurtbox_collision_duplicate.global_transform = collision_shape.global_transform
			
	await get_tree().process_frame
	freeze = false
