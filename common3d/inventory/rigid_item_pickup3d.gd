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
	var collision_shapes := item_pickup_interactable.generate_all_collision()
	for collision_shape in collision_shapes:
		var collision_duplicate: CollisionShape3D = collision_shape.duplicate()
		#collision_duplicate.scale = Vector3.ONE
		collision_duplicate.hide()
		add_child.call_deferred(collision_duplicate)
		
		if hurtbox:
			var hurtbox_collision_duplicate: CollisionShape3D = collision_shape.duplicate()
			#hurtbox_collision_duplicate.scale = Vector3.ONE
			hurtbox.add_child.call_deferred(hurtbox_collision_duplicate)
			
	await get_tree().process_frame
	freeze = false
